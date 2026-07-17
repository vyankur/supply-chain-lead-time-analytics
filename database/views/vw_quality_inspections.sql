-- =========================================================================
-- DEVELOPER PLACEHOLDER NOTICE (Ankur Varshney):
-- This SQL view represents your GE Power Supplier Quality inspections analytics view.
-- Replace base tables (tbl_inspections, tbl_deliveries, tbl_shipments, tbl_po_lines)
-- with your actual schema references when executing in production.
-- =========================================================================

CREATE OR REPLACE VIEW vw_quality_inspections AS
WITH inspection_summary AS (
    SELECT 
        insp.inspection_id,
        insp.inspection_date,
        insp.delivery_id,
        insp.inspector_id,
        insp.inspected_qty,
        insp.accepted_qty,
        insp.rejected_qty,
        insp.rejection_reason,
        
        -- Pull PO & Supplier metadata
        del.received_date,
        ship.po_line_id,
        po.po_number,
        po.supplier_id,
        po.supplier_name,
        po.item_id,
        po.item_description
    FROM tbl_inspections insp
    JOIN tbl_deliveries del ON insp.delivery_id = del.delivery_id
    JOIN tbl_shipments ship ON del.shipment_id = ship.shipment_id
    JOIN tbl_po_lines po ON ship.po_line_id = po.po_line_id
)
SELECT 
    inspection_id,
    inspection_date,
    delivery_id,
    po_number,
    supplier_id,
    supplier_name,
    item_id,
    item_description,
    inspected_qty,
    accepted_qty,
    rejected_qty,
    rejection_reason,
    
    -- Defect rates
    CASE 
        WHEN inspected_qty > 0 THEN ROUND((rejected_qty / inspected_qty) * 100, 2)
        ELSE 0 
    END AS defect_rate_percentage,
    
    -- Quality scoring
    CASE 
        WHEN inspected_qty = 0 THEN 100
        WHEN (rejected_qty / inspected_qty) = 0 THEN 100
        WHEN (rejected_qty / inspected_qty) <= 0.02 THEN 90
        WHEN (rejected_qty / inspected_qty) <= 0.05 THEN 75
        WHEN (rejected_qty / inspected_qty) <= 0.10 THEN 50
        ELSE 10
    END AS quality_score,
    
    -- Categorization of quality issues
    CASE 
        WHEN rejected_qty = 0 THEN 'PASSED'
        WHEN rejection_reason IN ('Damaged', 'Broken') THEN 'PHYSICAL DAMAGE'
        WHEN rejection_reason IN ('Incorrect Specifications', 'Dimension Mismatch') THEN 'SPECIFICATION ERROR'
        WHEN rejection_reason IN ('Testing Failed', 'Functionality Issue') THEN 'FUNCTIONAL FAILURE'
        ELSE 'OTHER QUALITY ISSUE'
    END AS defect_classification
FROM inspection_summary;
