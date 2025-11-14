# Breeding Analytics Implementation

This document describes the implementation of the new breeding analytics system that matches the functionality of the Flutter app dashboard.

## Overview

The breeding analytics system has been completely rewritten to provide the same sophisticated analysis logic as the Flutter app. The new system includes:

- **Advanced breeding success analysis** with proper pregnancy tracking
- **Comprehensive filtering** by Doe, Buck, breeding type, date range, and success status
- **Real-time analytics** with detailed performance metrics
- **Breeding type performance** analysis (Natural vs Artificial Insemination)
- **Buck performance tracking** with success rates and Doe counts
- **Pending breeding detection** for recent events

## Architecture

### 1. BreedingAnalyticsService (Core Service)

**Location**: `app/Services/BreedingAnalyticsService.php`

This is the core service that implements the breeding success analysis logic. It provides:

- `getBreedingSuccessAnalysis($filters)` - Main analysis method
- `getAvailableDoes($municipality)` - Get available Does for filtering
- `getAvailableBucks($municipality)` - Get available Bucks for filtering
- `getAvailableBreedingTypes()` - Get available breeding types

### 2. Controllers

**Admin**: `app/Controllers/Admin/BreedingAnalyticsController.php`
**PVO**: `app/Controllers/PVO/BreedingAnalyticsController.php`
**LGU**: `app/Controllers/LGU/BreedingAnalyticsController.php`

Each controller provides API endpoints for:
- `/breeding-analytics/analysis` - Get comprehensive breeding analysis
- `/breeding-analytics/available-Does` - Get available Does
- `/breeding-analytics/available-Bucks` - Get available Bucks
- `/breeding-analytics/available-types` - Get breeding types
- `/breeding-analytics/summary` - Get dashboard summary

### 3. Dashboard Integration

The existing dashboard controllers have been updated to use the new service:

- **Admin**: `app/Controllers/Admin/DashboardController.php`
- **PVO**: `app/Controllers/PVO/DashboardController.php`
- **LGU**: `app/Controllers/LGU/DashboardController.php`

### 4. Frontend Dashboard

**Location**: `resources/views/shared/breeding_analytics_dashboard.php`

A comprehensive dashboard view that provides:
- Advanced filtering capabilities
- Real-time statistics
- Visual charts and progress indicators
- Responsive design

## How It Works

### Breeding Success Logic

The system uses the same logic as the Flutter app:

1. **Event Collection**: Gathers breeding, pregnancy, and birth events
2. **Timeline Analysis**: Tracks the timeline between breeding and pregnancy/birth
3. **Success Determination**:
   - **Pending**: < 25 days since breeding
   - **Successful**: Pregnancy detected 25-60 days after breeding OR birth 280-300 days after breeding
   - **Failed**: > 60 days since breeding with no pregnancy/birth detected
4. **Buck Matching**: Ensures the same Buck is responsible for breeding and pregnancy/birth
5. **Breeding Type Detection**: Automatically determines breeding type from event data

### Data Structure

The analysis returns:

```json
{
  "overall_statistics": {
    "total_breedings": 150,
    "total_successful": 120,
    "total_failed": 20,
    "total_pending": 10,
    "overall_success_rate": 85.7
  },
  "breeding_type_performance": [
    {
      "type": "natural_breeding",
      "total_breedings": 80,
      "successful_breedings": 65,
      "success_rate": 81.3
    },
    {
      "type": "artificial_insemination",
      "total_breedings": 70,
      "successful_breedings": 55,
      "success_rate": 78.6
    }
  ],
  "Buck_performance": [
    {
      "Buck_tag": "Buck001",
      "total_breedings": 45,
      "successful_breedings": 38,
      "success_rate": 84.4,
      "Does_served": 35
    }
  ]
}
```

## Usage

### 1. Include in Dashboard

```php
// In your dashboard view
<?php 
$apiBaseUrl = '/admin/breeding-analytics'; // or /pvo/ or /lgu/
include 'resources/views/shared/breeding_analytics_dashboard.php';
?>
```

### 2. API Calls

```javascript
// Get breeding analysis
const response = await fetch('/admin/breeding-analytics/analysis?Doe_tag=Doe001');
const data = await response.json();

// Get available options
const Does = await fetch('/admin/breeding-analytics/available-Does').then(r => r.json());
const Bucks = await fetch('/admin/breeding-analytics/available-Bucks').then(r => r.json());
```

### 3. Filtering

The system supports comprehensive filtering:

- **Doe Tag**: Filter by specific Doe
- **Buck Tag**: Filter by specific Buck
- **Breeding Type**: Natural breeding, Artificial insemination, or All
- **Success Status**: Successful, Failed, or All
- **Date Range**: Start and end dates
- **Municipality**: For LGU users (automatically applied)

## Key Features

### 1. Smart Breeding Type Detection

The system automatically determines breeding type:
- **Natural Breeding**: When `Buck_tag` is present
- **Artificial Insemination**: When `semen_used` is present
- **Unknown**: When neither field is present

### 2. Pregnancy Tracking

- Tracks pregnancy events 25-60 days after breeding
- Tracks birth events 280-300 days after breeding
- Ensures Buck consistency between breeding and pregnancy/birth

### 3. Performance Metrics

- **Success Rate**: Based on resolved breedings (successful + failed)
- **Pending Breedings**: Recent breedings that need time to determine outcome
- **Buck Performance**: Individual Buck success rates and Doe counts
- **Breeding Type Comparison**: Natural vs Artificial insemination performance

### 4. Real-time Updates

- Automatic data refresh
- Filter-based real-time analysis
- Responsive UI with loading states

## Database Requirements

The system works with the existing `goat_events` table structure:

```sql
CREATE TABLE goat_events (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    goat_tag VARCHAR(20) NOT NULL,
    Buck_tag VARCHAR(20),
    event_type ENUM('Breeding', 'Pregnant', 'Gives Birth', ...) NOT NULL,
    event_date DATE NOT NULL,
    semen_used VARCHAR(100),
    breeding_date DATE,
    expected_delivery_date DATE,
    -- ... other fields
);
```

## Migration from Old System

The new system is backward compatible:

1. **Existing dashboards** continue to work with enhanced metrics
2. **New API endpoints** provide advanced functionality
3. **Fallback logic** ensures system stability if the new service fails

## Performance Considerations

- **Efficient SQL queries** with proper JOINs and indexing
- **Caching** of frequently accessed data
- **Lazy loading** of filter options
- **Optimized date calculations** for timeline analysis

## Security

- **Role-based access** (Admin, PVO, LGU)
- **Municipality filtering** for LGU users
- **Input validation** and SQL injection prevention
- **Error handling** without exposing sensitive information

## Future Enhancements

1. **Advanced Analytics**: Trend analysis, seasonal patterns
2. **Predictive Models**: Breeding success prediction
3. **Export Functionality**: PDF reports, Excel exports
4. **Mobile Optimization**: Responsive design improvements
5. **Real-time Notifications**: Breeding status updates

## Troubleshooting

### Common Issues

1. **No Data Displayed**: Check database connectivity and event data
2. **Filter Not Working**: Verify API endpoint URLs and parameters
3. **Performance Issues**: Check database indexes on event_date and goat_tag
4. **Permission Errors**: Verify user role and access rights

### Debug Mode

Enable debug logging in the service:

```php
// In BreedingAnalyticsService.php
error_log("DEBUG: Processing breeding event: " . json_encode($event));
```

## Support

For technical support or questions about the breeding analytics implementation, refer to:

- **Code Documentation**: Inline comments in service files
- **API Documentation**: Controller method documentation
- **Database Schema**: Migration files and table structures
- **Frontend Integration**: Dashboard view and JavaScript code
