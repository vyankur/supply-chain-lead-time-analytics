# Tableau Dashboard Specifications

This document outlines the detailed layout, logic, and metrics specifications for the GE Power Supply Chain Lead Time & Quality Dashboard.

## Dashboard Overview
The dashboard is composed of three primary tabs:
1. **Executive Snapshot**: Spend vs. general lead times, supplier SLA compliance card, and heatmaps showing critical delay regions.
2. **Supplier Risk Profile**: Multi-dimensional scoring card showing Quality Score vs. Lead Time performance.
3. **Item-Level Details**: Detailed grid with drill-down capability for purchase order line tracking and severity alerts.

---

## 1. Item-Level Drill-Down Specification
To allow users to trace delays from suppliers down to individual items, the dashboard implements a cross-sheet navigation filter.

- **Trigger**: Click on a specific Supplier segment in the *Supplier Risk Profile* scatter plot.
- **Action**: Activates filter on the *Item-Level details* table.
- **Drill-down Hierarchy**:
  ```
  Supplier Name
   └── Purchase Order Number
        └── PO Line Number
             └── Item Description
  ```

---

## 2. Predictive Completion Formula
For open purchase orders, the dashboard displays a predicted completion date based on historical lead times.

- **Tableau Calculated Field**: `[Predicted Delivery Date]`
- **Calculation Logic**:
  ```sql
  IF NOT ISNULL([Warehouse Received Date]) THEN
      [Warehouse Received Date]
  ELSEIF NOT ISNULL([Supplier Shipped Date]) THEN
      DATEADD('day', 7, [Supplier Shipped Date]) // Standard transit time default
  ELSE
      DATEADD('day', 14, [Po Released Date]) // Standard total lead time default
  END
  ```

---

## 3. Severity-Based Alert Rules
To call attention to critical delays, row items are highlighted based on their severity level.

- **KPI Field**: `[Delay Severity Level]`
- **Formatting Rules**:
  - **CRITICAL (Red Alert)**: Overdue shipments where the current date is > 10 days past `[Promised Delivery Date]`.
  - **HIGH (Orange Alert)**: Overdue shipments where the current date is <= 10 days past `[Promised Delivery Date]`.
  - **MEDIUM (Yellow Alert)**: Shipment was received late.
  - **LOW (Green Alert)**: Shipment is either on-time or pending within its scheduled window.
