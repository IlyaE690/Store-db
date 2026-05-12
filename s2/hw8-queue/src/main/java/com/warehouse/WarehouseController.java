package com.warehouse;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
public class WarehouseController {

    private final JdbcTemplate jdbcTemplate;

    public WarehouseController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/api/warehouse/status")
    public Map<String, Object> status() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("ready", jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM warehouse_tasks WHERE status = 'Ready'", Long.class));
        result.put("running", jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM warehouse_tasks WHERE status = 'Running'", Long.class));
        result.put("completed", jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM warehouse_tasks WHERE status = 'Completed'", Long.class));
        result.put("failed", jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM warehouse_tasks WHERE status = 'Failed'", Long.class));
        return result;
    }

    @GetMapping("/api/warehouse/lag")
    public Map<String, Object> lag() {
        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT COALESCE(EXTRACT(EPOCH FROM (now() - MIN(created_at))), 0) AS lag_seconds, " +
                        "COUNT(*) AS ready_count FROM warehouse_tasks WHERE status = 'Ready'");
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("lagSeconds", row.get("lag_seconds"));
        result.put("readyTasks", row.get("ready_count"));
        return result;
    }

    @GetMapping("/api/warehouse/tasks-by-type")
    public List<Map<String, Object>> tasksByType() {
        return jdbcTemplate.queryForList(
                "SELECT task_type, priority, status, COUNT(*) AS cnt " +
                        "FROM warehouse_tasks WHERE completed_at IS NOT NULL " +
                        "GROUP BY task_type, priority, status ORDER BY priority DESC");
    }

    @GetMapping("/api/metrics/dashboard")
    public Map<String, Object> dashboard() {
        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT COALESCE(EXTRACT(EPOCH FROM (now() - MIN(created_at))), 0) AS lag_seconds, " +
                        "COUNT(*) AS ready_count FROM warehouse_tasks WHERE status = 'Ready'");
        Long completedPerMin = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM warehouse_tasks " +
                        "WHERE status IN ('Completed', 'Failed') AND completed_at >= now() - INTERVAL '1 minute'", Long.class);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("lagSeconds", row.get("lag_seconds"));
        result.put("readyTasks", row.get("ready_count"));
        result.put("completedPerMinute", completedPerMin);
        return result;
    }
}