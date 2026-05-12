package com.warehouse;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface WarehouseTaskRepository extends JpaRepository<WarehouseTask, Long> {

    @Query(value = """
            SELECT * FROM warehouse_tasks
            WHERE status = 'Ready' AND scheduled_at <= now()
            ORDER BY priority DESC, scheduled_at ASC
            FOR UPDATE SKIP LOCKED
            LIMIT 1
            """, nativeQuery = true)
    Optional<WarehouseTask> findReadyTaskForUpdate();
}