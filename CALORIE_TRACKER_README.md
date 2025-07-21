# Calorie Tracker Feature

## Overview

A simple calorie tracking system has been added to the Calories tab on the home page. Users can now track their daily food and drink consumption with calorie counts.

## Features

### 1. Daily Calorie Summary

- Displays total calories consumed for the current day
- Shows a prominent calorie counter with fire icon
- Updates in real-time as entries are added or removed

### 2. Add Calorie Entries

- Simple form to add food/drink items
- Fields for:
  - Food/Drink name
  - Calorie count
  - Optional notes (e.g., "Large size", "With cream")
- Form validation ensures required fields are filled

### 3. Entry Management

- View all today's entries in a clean list
- Each entry shows:
  - Food/drink name
  - Calorie count
  - Time added
  - Optional notes
- Delete entries with a single tap
- Empty state with helpful guidance

### 4. Data Persistence

- All entries are stored in Firebase Firestore
- Data is tied to the authenticated user
- Entries are automatically organized by date

## Technical Implementation

### Models

- `CalorieEntry`: Data model for calorie entries
  - `id`: Unique identifier
  - `name`: Food/drink name
  - `calories`: Calorie count
  - `date`: Timestamp
  - `userId`: User identifier
  - `notes`: Optional notes

### Services

- `CalorieTrackingService`: Handles all calorie tracking operations
  - `addCalorieEntry()`: Add new entries
  - `getCalorieEntriesForDate()`: Get entries for specific date
  - `getTotalCaloriesForDate()`: Calculate daily total
  - `deleteCalorieEntry()`: Remove entries
  - `getDailyCalorieTotals()`: Get weekly summary

### UI Components

- `CaloriesTab`: Main tab widget with complete calorie tracking interface
- Responsive design that works with both light and dark themes
- Loading states and error handling
- User-friendly feedback with snackbar messages

## Usage

1. Navigate to the Home page
2. Tap the "Calories" tab
3. View today's calorie total
4. Tap "Add Food/Drink" to add new entries
5. Fill in the food name and calorie count
6. Optionally add notes
7. Tap "Add" to save the entry
8. View and manage entries in the list below
9. Tap the delete icon to remove entries

## Database Structure

The calorie entries are stored in a `calorie_entries` collection in Firestore with the following structure:

```json
{
  "name": "Apple",
  "calories": 95,
  "date": "2024-01-15T10:30:00Z",
  "userId": "user123",
  "notes": "Large red apple"
}
```

## Future Enhancements

Potential improvements for the calorie tracker:

- Calorie goals and progress tracking
- Weekly/monthly calorie summaries
- Food database integration
- Barcode scanning for packaged foods
- Meal categorization (breakfast, lunch, dinner, snacks)
- Nutritional information beyond calories
- Export functionality
- Calorie burn integration with workout data
