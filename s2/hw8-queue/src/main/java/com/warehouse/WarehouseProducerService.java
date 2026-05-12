package com.warehouse;

import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Random;

@Service
@Profile("producer")
public class WarehouseProducerService {

    private final WarehouseTaskRepository repository;
    private final Random random = new Random();

    private static final String[] TYPES = {
            "RECEIVING", "INVENTORY", "PICKING", "SHIPPING", "QUALITY_CONTROL"
    };
    private static final String[] ZONES = {
            "A-01", "A-02", "B-01", "B-02", "C-01", "C-02", "D-01", "D-02", "Q-01"
    };
    private static final String[][] PRODUCTS = {
            {"SKU-001", "Ноутбук Lenovo ThinkPad", "шт"},
            {"SKU-002", "Монитор Dell 27\"", "шт"},
            {"SKU-003", "Сервер HP ProLiant", "шт"},
            {"SKU-004", "SSD Samsung 1TB", "шт"},
            {"SKU-005", "Блок питания 750W", "шт"}
    };

    public WarehouseProducerService(WarehouseTaskRepository repository) {
        this.repository = repository;
    }

    @Scheduled(fixedDelay = 10)
    @Transactional
    public void generateTask() {
        String[] product = PRODUCTS[random.nextInt(PRODUCTS.length)];
        String zone = ZONES[random.nextInt(ZONES.length)];

        WarehouseTask task = new WarehouseTask();
        task.setTaskType(TYPES[random.nextInt(TYPES.length)]);
        task.setPriority(random.nextInt(100) < 20 ? 100 : 0);
        task.setZoneId(zone);
        task.setProductSku(product[0]);
        task.setProductName(product[1]);
        task.setUnit(product[2]);
        task.setQuantity(1 + random.nextInt(100));

        repository.save(task);
    }
}