package com.warehouse;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Optional;

@Service
public class WarehouseTaskService {

    private final WarehouseTaskRepository repository;

    public WarehouseTaskService(WarehouseTaskRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public WarehouseTask takeTask(String workerId) {
        Optional<WarehouseTask> opt = repository.findReadyTaskForUpdate();
        if (opt.isPresent()) {
            WarehouseTask task = opt.get();
            task.setStatus("Running");
            task.setAssignedTo(workerId);
            task.setStartedAt(OffsetDateTime.now());
            return repository.save(task);
        }
        return null;
    }

    @Transactional
    public void finTask(WarehouseTask task, boolean success, String errorCode, String errorMessage) {
        if (success) {
            task.setStatus("Completed");
            task.setCompletedAt(OffsetDateTime.now());
        } else {
            task.setAttempts(task.getAttempts() + 1);
            task.setErrorMessage(errorMessage);
            task.setErrorCode(errorCode);
            if (task.getAttempts() >= task.getMaxAttempts()) {
                task.setStatus("Failed");
                task.setCompletedAt(OffsetDateTime.now());
            } else {
                task.setStatus("Ready");
                long backoffSeconds = (long) Math.pow(2, task.getAttempts()) * 60;
                task.setScheduledAt(OffsetDateTime.now().plusSeconds(backoffSeconds));
            }
        }
        repository.save(task);
    }
}