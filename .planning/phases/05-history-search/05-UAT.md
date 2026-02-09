---
status: testing
phase: 05-history-search
source: 05-01-SUMMARY.md, 05-02-SUMMARY.md
started: 2026-02-09T22:52:00Z
updated: 2026-02-09T22:52:00Z
---

## Current Test

number: 1
name: Search brew notes with text filter
expected: |
  Type text in the search bar at the top of the Brews tab. The brew list should filter in real-time to show only brews whose notes contain the search text. Clearing the search should show all brews again.
awaiting: user response

## Tests

### 1. Search brew notes with text filter
expected: Type text in the search bar at the top of the Brews tab. The brew list should filter in real-time to show only brews whose notes contain the search text. Clearing the search should show all brews again.
result: [pending]

### 2. Open advanced filter sheet
expected: Tap the filter icon in the toolbar (top-right). A modal sheet titled "Filter Brews" should appear with pickers for Method, Coffee, Date Range toggle, and Minimum Rating.
result: [pending]

### 3. Filter by method
expected: In the filter sheet, select a specific brew method from the Method picker. Dismiss the sheet. The brew list should show only brews using that method. The filter icon should appear filled (active state).
result: [pending]

### 4. Filter by coffee bean
expected: In the filter sheet, select a specific coffee bean from the Coffee picker. Dismiss the sheet. The brew list should show only brews using that bean. The filter icon should appear filled.
result: [pending]

### 5. Filter by date range
expected: In the filter sheet, toggle "Filter by date" ON. Two date pickers (From/To) should appear with From defaulting to 30 days ago and To defaulting to today. Select a date range. Dismiss the sheet. The brew list should show only brews within that date range.
result: [pending]

### 6. Filter by minimum rating
expected: In the filter sheet, select a minimum rating (e.g., "3+ stars"). Dismiss the sheet. The brew list should show only brews with rating >= 3. The filter icon should appear filled.
result: [pending]

### 7. Combine multiple filter criteria
expected: Apply multiple filters simultaneously (e.g., search text + method + date range). The brew list should show only brews matching ALL criteria at once.
result: [pending]

### 8. Clear all filters
expected: With active filters applied, open the filter sheet and tap "Clear All Filters". All pickers reset to "All Methods", "All Coffees", rating to "Any", and date toggle OFF. Dismiss the sheet. The full brew list should appear and the filter icon should be unfilled.
result: [pending]

### 9. Empty state with active filters
expected: Apply filters that match zero brews (e.g., search for nonsense text). The list should show an empty state with "No Matches" title and a message like "Try adjusting your filters or search text".
result: [pending]

### 10. Navigate to statistics dashboard
expected: Tap the statistics icon (chart.bar.xaxis) in the toolbar (top-left). A statistics dashboard screen should appear showing summary stat cards and charts.
result: [pending]

### 11. View summary stat cards
expected: On the statistics dashboard, see four stat cards in a 2-column grid showing: Total Brews (count), Avg Rating (X.X format), Top Method (most frequent method name), and Top Bean (most frequent bean name).
result: [pending]

### 12. View method distribution chart
expected: On the statistics dashboard, scroll to the "Brews by Method" section. A bar chart should show methods on the x-axis and brew count on the y-axis, using monochrome gray bars.
result: [pending]

### 13. View rating trend chart
expected: On the statistics dashboard, scroll to the "Rating Trend" section. A line chart with data points should show months on the x-axis and average rating (0-5) on the y-axis, using monochrome styling.
result: [pending]

### 14. View brew frequency chart
expected: On the statistics dashboard, scroll to the "Brew Frequency" section. A bar chart should show months on the x-axis and brew count on the y-axis with abbreviated month labels (Jan, Feb, etc.).
result: [pending]

### 15. View top beans chart
expected: On the statistics dashboard, scroll to the bottom. A horizontal bar chart should show the top 5 beans with bean names on the y-axis and brew count on the x-axis.
result: [pending]

### 16. Statistics empty state
expected: If no brews exist in the app, the statistics dashboard should show an empty state with a chart.bar icon, title "No Statistics Yet", and message "Log some brews to see your stats".
result: [pending]

## Summary

total: 16
passed: 0
issues: 0
pending: 16
skipped: 0

## Gaps

[none yet]
