# Tableau Dashboard Performance Tuning Report

This report outlines the performance diagnostics performed using **Tableau Performance Recording** and the subsequent database optimizations that reduced dashboard load times by **35%**.

## Diagnostics Summary

During initial deployment, the lead time dashboard suffered from high query response latency. We activated Tableau Performance Recording (`Help > Settings and Performance > Start Performance Recording`) to identify the bottlenecks.

### Before Optimization (Load Time: 12.4 seconds)
- **High latency events**: "Executing Query" comprised 78% of the load duration.
- **Root Cause**: Tableau was generating nested subqueries with complex string parsing functions to calculate stage-by-stage differences in days (`DATEDIFF`) on un-indexed timestamps.
- **Cross-Database Joins**: Multiple joins between transactional Oracle tables and Excel-based target sheets were processed in Tableau's local engine.

## Action Plan & Implementation

We resolved these issues by moving business computations closer to the database layer and configuring strict caching:

```
[ Tableau Local Calculations ]  --> MOVE DOWN -->  [ Database Analytical Views ]
[ Live Cross-Database Joins  ]  --> MOVE DOWN -->  [ Daily Talend ETL Snapshots ]
```

### 1. Database Pushdown
- Refactored `DATEDIFF` logic into the Oracle view `vw_supply_chain_lead_time` using Oracle date subtraction arithmetic (`TRUNC(warehouse_received_date) - TRUNC(po_released_date)`).
- Eliminated cross-database Excel joins by importing targets directly into `tbl_projects` in the Oracle database via Talend ETL.

### 2. Tableau Indexing & Filtering Optimization
- Created database indexes on joining fields: `po_header_id` and `item_id`.
- Configured Tableau **Context Filters** for `Region` and `Supplier` so Tableau generates temporary tables on the database, preventing constant query re-runs for secondary worksheets.

### After Optimization (Load Time: 8.1 seconds)
- **Query response latency**: Reduced from 9.7 seconds to 2.1 seconds.
- **Cache Hit Ratio**: Increased to 84% on the Tableau Server due to standardized context filters.
- **Overall Performance Improvement**: **35% reduction in dashboard rendering time**.
