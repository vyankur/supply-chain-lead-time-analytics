-- =========================================================================
-- DEVELOPER PLACEHOLDER NOTICE (Ankur Varshney):
-- This SQL view represents your GE Power Supply Chain Lead Time database logic.
-- Replace the staging tables (tbl_po_lines, tbl_shipments, tbl_deliveries)
-- with your actual schema references when executing in production.
-- =========================================================================

CREATE OR REPLACE VIEW vw_supply_chain_lead_time AS
WITH stage_timestamps AS (
    SELECT 
        po.po_header_id,
        po.po_number,
        po.supplier_id,
        po.supplier_name,
        po.item_id,
        po.item_description,
        po.order_qty,
        po.unit_price,
        po.order_qty * po.unit_price AS line_spend,
        po.creation_date AS po_released_date,
        
        -- Shipments
        ship.shipment_id,
        ship.shipment_date AS supplier_shipped_date,
        ship.carrier_name,
        ship.shipping_mode,
        
        -- Deliveries
        del.delivery_id,
        del.received_date AS warehouse_received_date,
        del.received_qty,
        
        -- Scheduled dates
        po.promised_delivery_date
    FROM tbl_po_lines po
    LEFT JOIN tbl_shipments ship ON po.po_line_id = ship.po_line_id
    LEFT JOIN tbl_deliveries del ON ship.shipment_id = del.shipment_id
),
lead_time_calculations AS (
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
        
        -- Lead time days calculations (Oracle syntax)
        TRUNC(supplier_shipped_date) - TRUNC(po_released_date) AS lead_time_order_to_ship_days,
        TRUNC(warehouse_received_date) - TRUNC(supplier_shipped_date) AS lead_time_transit_days,
        TRUNC(warehouse_received_date) - TRUNC(po_released_date) AS total_lead_time_days,
        
        -- Compliance calculations
        CASE 
            WHEN warehouse_received_date IS NOT NULL AND warehouse_received_date <= promised_delivery_date THEN 'ON-TIME'
            WHEN warehouse_received_date IS NOT NULL AND warehouse_received_date > promised_delivery_date THEN 'LATE'
            WHEN warehouse_received_date IS NULL AND SYSDATE <= promised_delivery_date THEN 'PENDING (IN-WINDOW)'
            ELSE 'OVERDUE'
        END AS delivery_status,
        
        -- Expected completion date forecasting
        CASE 
            WHEN warehouse_received_date IS NOT NULL THEN warehouse_received_date
            WHEN supplier_shipped_date IS NOT NULL THEN supplier_shipped_date + 7 -- Average transit time
            ELSE po_released_date + 14 -- Average total lead time
        END AS predicted_delivery_date
    FROM stage_timestamps
)
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
    
    -- Severity levels for overdue or delayed shipments
    CASE 
        WHEN delivery_status = 'OVERDUE' AND (SYSDATE - promised_delivery_date) > 10 THEN 'CRITICAL'
        WHEN delivery_status = 'OVERDUE' AND (SYSDATE - promised_delivery_date) <= 10 THEN 'HIGH'
        WHEN delivery_status = 'LATE' THEN 'MEDIUM'
        ELSE 'LOW'
    END AS delay_severity_level
FROM lead_time_calculations;
