CREATE TABLE IF NOT EXISTS warehouse_tasks (
                                               id BIGSERIAL PRIMARY KEY,
                                               task_type VARCHAR(30) NOT NULL,
    priority INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Ready',
    warehouse_id VARCHAR(20) NOT NULL DEFAULT 'WH-MSK-001',
    zone_id VARCHAR(10),
    product_sku VARCHAR(20),
    product_name VARCHAR(200),
    quantity INT DEFAULT 1,
    unit VARCHAR(10) DEFAULT 'шт',
    metadata JSONB DEFAULT '{}',
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    assigned_to VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    error_code VARCHAR(20),
    actual_quantity INT,
    weight_kg DECIMAL(10,2)
    );

CREATE INDEX IF NOT EXISTS idx_tasks_fetch
    ON warehouse_tasks (status, priority DESC, scheduled_at ASC)
    WHERE status = 'Ready';

ALTER TABLE warehouse_tasks SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_threshold = 1000
    );

CREATE OR REPLACE FUNCTION notify_warehouse_task()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('warehouse_task_channel',
        json_build_object('id', NEW.id, 'priority', NEW.priority)::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS warehouse_task_notify ON warehouse_tasks;
CREATE TRIGGER warehouse_task_notify
    AFTER INSERT ON warehouse_tasks
    FOR EACH ROW
    EXECUTE FUNCTION notify_warehouse_task();