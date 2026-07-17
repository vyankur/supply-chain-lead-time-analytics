# Supply Chain Lead Time & Quality Analytics

An enterprise-grade business intelligence and database solutions project designed for monitoring supply chain lead times and quality metrics. This repository is modeled after the solutions implemented for **GE Power** to optimize procurement workflows, track delivery risks, and ensure master data quality.

## Business Context & Objectives

In large-scale manufacturing and energy sectors, supply chain delays directly translate into expensive production downtime. Evaluating supplier performance requires tracking:
1. **Lead Time Performance**: Measuring transit durations between purchase order release, supplier dispatch, shipping transit, customs clearance, and warehouse receipt.
2. **Quality Compliance**: Monitoring defect rates of received shipments at the item level.
3. **Delivery Risk**: Predicting late shipments using historical lead times and raising severity-based alerts.

This repository showcases the database models, ETL job architectures, and dashboard specifications that achieved a **35% reduction in load times** through query optimization and Tableau performance tuning.

## Project Architecture

```mermaid
graph TD
    subgraph Source Systems
        ERP[ERP Oracle DB]
        WMS[Warehouse Management System]
    end

    subgraph ETL Layer (Talend)
        ETL_Job[Talend Lead Time Job]
    end

    subgraph Data Warehousing (Oracle SQL)
        Raw_Tables[Staging Tables]
        Snapshots[Reporting Snapshots]
        Views[Analytical Views]
    end

    subgraph Reporting Layer (Tableau)
        T_Desktop[Tableau Desktop Dashboard]
        T_Server[Tableau Server Scheduler]
    end

    ERP --> ETL_Job
    WMS --> ETL_Job
    ETL_Job --> Raw_Tables
    Raw_Tables --> Snapshots
    Snapshots --> Views
    Views --> T_Desktop
    T_Desktop --> T_Server
```

## Repository Structure

- `database/`: Oracle SQL/PL/SQL models
  - `views/vw_supply_chain_lead_time.sql`: Analytical view calculating stage-by-stage transit times and forecasting completion.
  - `views/vw_quality_inspections.sql`: Analytical view computing defect rates and quality scores.
  - `procedures/sp_load_lead_time_snapshots.sql`: Stored procedure implementing incremental snapshot updates.
- `talend/`: ETL job configurations
  - `jobs/talend_job_architecture.md`: Visual layout and properties of the Talend ETL jobs.
- `tableau/`: Visualization specifications
  - `performance/performance_tuning_report.md`: Tableau Performance Recording analysis and query tuning strategies.
  - `dashboards/dashboard_specifications.md`: Specifications for item-level drill-downs, predictive completion formulas, and severity alerts.

## Performance Optimization Summary

Through targeted refactoring of the reporting queries and Tableau dashboard design, performance was tuned by **35%**:
- **Indexed Views**: Replaced ad-hoc calculations in Tableau with structured Oracle SQL views, pushing processing down to the database.
- **Incremental Snapshots**: Refactored the Talend ETL from full table refreshes to incremental daily snapshots via PL/SQL stored procedures.
- **Context Filtering**: Optimized Tableau Context filters to minimize cache invalidation on the Tableau Server.
