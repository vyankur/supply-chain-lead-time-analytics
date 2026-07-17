-- =========================================================================
-- DEVELOPER PLACEHOLDER NOTICE (Ankur Varshney):
-- This PL/SQL stored procedure represents your incremental snapshot loading logic.
-- Replace fact snapshot tables and log references with your actual
-- database schema references.
-- =========================================================================

CREATE OR REPLACE PROCEDURE sp_load_lead_time_snapshots AS
    v_rows_inserted NUMBER := 0;
    v_rows_updated  NUMBER := 0;
    v_process_date  DATE := SYSDATE;
BEGIN
    -- Log start of procedure execution
    INSERT INTO tbl_etl_log (process_name, status, log_message, created_at)
    VALUES ('SP_LOAD_LEAD_TIME_SNAPSHOTS', 'START', 'Beginning daily incremental run.', v_process_date);
    
    -- Perform upsert of supply chain data into reporting table
    MERGE INTO tbl_fact_lead_time_snapshot target
    USING (
        SELECT 
            po_header_id,
            po_number,
            supplier_id,
            supplier_name,
            item_id,
            item_description,
            order_qty,
            received_qty,
            line_spend,
            po_released_date,
            supplier_shipped_date,
            warehouse_received_date,
            promised_delivery_date,
            carrier_name,
            shipping_mode,
            lead_time_order_to_ship_days,
            lead_time_transit_days,
            total_lead_time_days,
            delivery_status,
            predicted_delivery_date,
            delay_severity_level
        FROM vw_supply_chain_lead_time
        WHERE po_released_date >= v_process_date - 30 -- Scan last 30 days for updates
    ) source
    ON (target.po_header_id = source.po_header_id AND target.item_id = source.item_id)
    WHEN MATCHED THEN
        UPDATE SET 
            target.received_qty = source.received_qty,
            target.supplier_shipped_date = source.supplier_shipped_date,
            target.warehouse_received_date = source.warehouse_received_date,
            target.total_lead_time_days = source.total_lead_time_days,
            target.delivery_status = source.delivery_status,
            target.predicted_delivery_date = source.predicted_delivery_date,
            target.delay_severity_level = source.delay_severity_level,
            target.updated_at = v_process_date
        WHERE target.delivery_status != source.delivery_status OR target.received_qty != source.received_qty
    WHEN NOT MATCHED THEN
        INSERT (
            po_header_id, po_number, supplier_id, supplier_name, item_id, item_description,
            order_qty, received_qty, line_spend, po_released_date, supplier_shipped_date,
            warehouse_received_date, promised_delivery_date, carrier_name, shipping_mode,
            lead_time_order_to_ship_days, lead_time_transit_days, total_lead_time_days,
            delivery_status, predicted_delivery_date, delay_severity_level, created_at, updated_at
        )
        VALUES (
            source.po_header_id, source.po_number, source.supplier_id, source.supplier_name, source.item_id, source.item_description,
            source.order_qty, source.received_qty, source.line_spend, source.po_released_date, source.supplier_shipped_date,
            source.warehouse_received_date, source.promised_delivery_date, source.carrier_name, source.shipping_mode,
            source.lead_time_order_to_ship_days, source.lead_time_transit_days, source.total_lead_time_days,
            source.delivery_status, source.predicted_delivery_date, source.delay_severity_level, v_process_date, v_process_date
        );

    -- Capture merge counts
    v_rows_inserted := SQL%ROWCOUNT;
    
    -- Log completion
    INSERT INTO tbl_etl_log (process_name, status, log_message, created_at)
    VALUES ('SP_LOAD_LEAD_TIME_SNAPSHOTS', 'COMPLETE', 'Successfully completed daily run. Rows processed: ' || v_rows_inserted, v_process_date);
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        INSERT INTO tbl_etl_log (process_name, status, log_message, created_at)
        VALUES ('SP_LOAD_LEAD_TIME_SNAPSHOTS', 'ERROR', 'Error occurred: ' || SQLERRM, v_process_date);
        COMMIT;
        RAISE;
END;
/
