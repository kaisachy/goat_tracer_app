# Breeding Analytics Implementation

This document describes the implementation of the new breeding analytics system that matches the functionality of the Flutter app dashboard.

## Overview

The breeding analytics system has been completely rewritten to provide the same sophisticated analysis logic as the Flutter app. The new system includes:

- **Advanced breeding success analysis** with proper pregnancy tracking
- **Comprehensive filtering** by cow, bull, breeding type, date range, and success status
- **Real-time analytics** with detailed performance metrics
- **Breeding type performance** analysis (Natural vs Artificial Insemination)
- **Bull performance tracking** with success rates and cow counts
- **Pending breeding detection** for recent events

## Architecture

### 1. BreedingAnalyticsService (Core Service)

**Location**: `app/Services/BreedingAnalyticsService.php`

This is the core service that implements the breeding success analysis logic. It provides:

- `getBreedingSuccessAnalysis($filters)` - Main analysis method
- `getAvailableCows($municipality)` - Get available cows for filtering
- `getAvailableBulls($municipality)` - Get available bulls for filtering
- `getAvailableBreedingTypes()` - Get available breeding types

### 2. Controllers

**Admin**: `app/Controllers/Admin/BreedingAnalyticsController.php`
**PVO**: `app/Controllers/PVO/BreedingAnalyticsController.php`
**LGU**: `app/Controllers/LGU/BreedingAnalyticsController.php`

Each controller provides API endpoints for:
- `/breeding-analytics/analysis` - Get comprehensive breeding analysis
- `/breeding-analytics/available-cows` - Get available cows
- `/breeding-analytics/available-bulls` - Get available bulls
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
4. **Bull Matching**: Ensures the same bull is responsible for breeding and pregnancy/birth
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
  "bull_performance": [
    {
      "bull_tag": "BULL001",
      "total_breedings": 45,
      "successful_breedings": 38,
      "success_rate": 84.4,
      "cows_served": 35
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
const response = await fetch('/admin/breeding-analytics/analysis?cow_tag=COW001');
const data = await response.json();

// Get available options
const cows = await fetch('/admin/breeding-analytics/available-cows').then(r => r.json());
const bulls = await fetch('/admin/breeding-analytics/available-bulls').then(r => r.json());
```

### 3. Filtering

The system supports comprehensive filtering:

- **Cow Tag**: Filter by specific cow
- **Bull Tag**: Filter by specific bull
- **Breeding Type**: Natural breeding, Artificial insemination, or All
- **Success Status**: Successful, Failed, or All
- **Date Range**: Start and end dates
- **Municipality**: For LGU users (automatically applied)

## Key Features

### 1. Smart Breeding Type Detection

The system automatically determines breeding type:
- **Natural Breeding**: When `bull_tag` is present
- **Artificial Insemination**: When `semen_used` is present
- **Unknown**: When neither field is present

### 2. Pregnancy Tracking

- Tracks pregnancy events 25-60 days after breeding
- Tracks birth events 280-300 days after breeding
- Ensures bull consistency between breeding and pregnancy/birth

### 3. Performance Metrics

- **Success Rate**: Based on resolved breedings (successful + failed)
- **Pending Breedings**: Recent breedings that need time to determine outcome
- **Bull Performance**: Individual bull success rates and cow counts
- **Breeding Type Comparison**: Natural vs Artificial insemination performance

### 4. Real-time Updates

- Automatic data refresh
- Filter-based real-time analysis
- Responsive UI with loading states

## Database Requirements

The system works with the existing `cattle_events` table structure:

```sql
CREATE TABLE cattle_events (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    cattle_tag VARCHAR(20) NOT NULL,
    bull_tag VARCHAR(20),
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
3. **Performance Issues**: Check database indexes on event_date and cattle_tag
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
