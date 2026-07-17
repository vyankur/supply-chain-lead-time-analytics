# Talend ETL Job Architecture

This document describes the structure and properties of the Talend jobs developed to orchestrate data movement from source ERP and WMS databases into the Oracle Reporting Data Warehouse.

## Job Flow: `job_load_supply_chain_data`

```
  tOracleInput (ERP) ---\
                         tMap (Join & Transform) ---> tOracleOutput (tbl_po_lines staging)
  tOracleInput (WMS) ---/
            |
       (OnSubjobOk)
            |
    tOracleRow (Call sp_load_lead_time_snapshots)
```

### Component Details

1. **`tOracleInput_1` (ERP ERP_PO_DATA)**:
   - Queries the transaction systems for purchase order header and line details.
   - SQL Query:
     ```sql
     SELECT po_header_id, po_number, item_id, item_desc, qty_ordered, price, creation_date, promised_date 
     FROM erp.po_lines 
     WHERE last_update_date >= :last_run_date
     ```
2. **`tOracleInput_2` (WMS WMS_RECEIPT_DATA)**:
   - Queries the warehouse management database for receiving logs.
   - SQL Query:
     ```sql
     SELECT receipt_id, shipment_id, date_received, qty_received 
     FROM wms.receipts 
     WHERE date_received >= :last_run_date
     ```
3. **`tMap_1`**:
   - Performs inner joins on item IDs and maps variables.
   - Standardizes character schemas and handles null attributes in shipments.
4. **`tOracleOutput_1`**:
   - Writes staging records into `tbl_po_lines` using bulk insert operations.
5. **`tOracleRow_1`**:
   - Triggers the PL/SQL stored procedure to compile snapshots:
   - SQL Statement: `CALL sp_load_lead_time_snapshots()`

### Scheduled Execution

- **Frequency**: Configured to execute daily at 01:00 AM.
- **Dependency**: Uses a Talend context variable loaded from an ETL status table to fetch the last runtime stamp for incremental extraction.
