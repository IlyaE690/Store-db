package com.warehouse;

import jakarta.annotation.PostConstruct;
import org.postgresql.PGConnection;
import org.postgresql.PGNotification;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;
import java.util.Random;
import java.util.UUID;

@Service
@Profile("consumer")
public class WarehouseConsumerWorker {

    private final WarehouseTaskService taskService;
    private final DataSource dataSource;
    private final String workerId;
    private final Random random = new Random();

    public WarehouseConsumerWorker(WarehouseTaskService taskService, DataSource dataSource) {
        this.taskService = taskService;
        this.dataSource = dataSource;
        this.workerId = "EMP-" + UUID.randomUUID().toString().substring(0, 6);
    }

    @PostConstruct
    public void initListener() {
        Thread listenerThread = new Thread(() -> {
            try (Connection conn = dataSource.getConnection()) {
                PGConnection pgConn = conn.unwrap(PGConnection.class);
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute("LISTEN warehouse_task_channel");
                }

                System.out.println(workerId + " started. Listening for warehouse tasks...");

                processAvailableTasks();

                while (!Thread.currentThread().isInterrupted()) {
                    PGNotification[] notifications = pgConn.getNotifications(1000);

                    if (notifications != null && notifications.length > 0) {
                        processAvailableTasks();
                    } else {
                        processAvailableTasks();
                    }
                }
            } catch (Exception e) {
                System.err.println(workerId + " listener error: " + e.getMessage());
            }
        });
        listenerThread.start();
    }

    private void processAvailableTasks() {
        WarehouseTask task;
        while ((task = taskService.takeTask(workerId)) != null) {
            try {
                int baseTime = task.getPriority() >= 50 ? 20 + random.nextInt(30) : 50 + random.nextInt(150);
                Thread.sleep(baseTime);

                boolean success = random.nextInt(100) >= 10;

                if (success) {
                    taskService.finTask(task, true, null, null);
                    System.out.println(workerId + " completed task #" + task.getId() + " (" + task.getTaskType() + ")");
                } else {
                    String errorCode;
                    String errorMessage;
                    double rand = random.nextDouble();
                    if (rand < 0.4) {
                        errorCode = "DAMAGED";
                        errorMessage = "Повреждение товара " + task.getProductName() + " в зоне " + task.getZoneId();
                    } else if (rand < 0.7) {
                        errorCode = "MISMATCH";
                        errorMessage = "Несоответствие количества " + task.getProductName();
                    } else if (rand < 0.9) {
                        errorCode = "OVERWEIGHT";
                        errorMessage = "Превышение веса для " + task.getProductName() + " в зоне " + task.getZoneId();
                    } else {
                        errorCode = "ZONE_BLOCKED";
                        errorMessage = "Зона " + task.getZoneId() + " заблокирована";
                    }

                    taskService.finTask(task, false, errorCode, errorMessage);
                    System.out.println(workerId + " failed task #" + task.getId() + " - " + errorCode + " (attempt " + (task.getAttempts() + 1) + ")");
                }

            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                taskService.finTask(task, false, "SYSTEM_ERROR", e.getMessage());
            }
        }
    }
}