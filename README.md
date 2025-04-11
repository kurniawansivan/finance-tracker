# Finance Tracker

A personal finance tracker digital wallet application built with Flutter. This app helps you manage your finances by tracking income, expenses, transfers, savings, and budgets across multiple accounts.

## Features

- **Dashboard**: View a summary of your financial situation with total balance, income, expenses, and savings
- **Expense Analysis**: Visualize your spending with pie charts by category
- **Account Management**: Add and manage multiple accounts with different types (cash, bank, credit card, investment, savings)
- **Transaction Tracking**: Record expenses, income, transfers, and savings with detailed categories
- **Budget Planning**: Create and track budgets for different categories and time periods
- **Multi-Currency Support**: Track finances in your preferred currency
- **Secure Local Storage**: All your financial data stays on your device

## Screenshots

[Screenshots will be added here when available]

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code with Flutter extension
- An Android or iOS device/emulator

### Installation

1. Clone this repository
   ```
   git clone https://github.com/yourusername/finance_tracker.git
   ```

2. Navigate to the project folder
   ```
   cd finance_tracker
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## Architecture

This app follows a Provider pattern architecture for state management:

- **Models**: Define the data structures for transactions, categories, accounts, and budgets
- **Providers**: Manage state and business logic using the Provider package
- **Screens**: UI components and pages
- **Services**: Handle database operations and other core functionality
- **Widgets**: Reusable UI components

## Database Structure

The app uses SQLite for local storage with the following tables:

- **accounts**: Stores different financial accounts
- **categories**: Tracks expense and income categories
- **transactions**: Records all financial transactions
- **budgets**: Stores budget information

## Future Enhancements

- Cloud synchronization for multi-device access
- Reports and analytics
- Data export (CSV, PDF)
- Goals tracking
- Recurring transactions
- Bill reminders
- Dark mode theme

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Acknowledgments

- Flutter team for the amazing framework
- Provider package for state management
- FL Chart for beautiful financial visualizations
