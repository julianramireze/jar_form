# JAR Form: Reactive Form Management for Flutter

[![pub package](https://img.shields.io/pub/v/jar_form.svg)](https://pub.dev/packages/jar_form)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

JAR Form is a powerful reactive form management library for Flutter that works seamlessly with the JAR validation library. Build type-safe, reactive forms with real-time validation, field tracking, and simplified state management.

## Features

- 🔄 **Reactive forms** with real-time validation feedback
- 🔄 **Two-way data binding** between form fields and UI
- 🧩 **Seamless integration** with JAR validation schemas
- 📊 **Form state tracking** (dirty, touched, valid, submitting)
- 🔄 **Async validators** for server-side or complex validations
- 📱 **Flutter-friendly** components for quick form implementation
- 🪶 **Lightweight** with minimal external dependencies

## Installation

```bash
flutter pub add jar_form
flutter pub add jar  # If you haven't already installed the JAR validation library
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/jar_form.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formController = JarFormController();
  
  final _loginSchema = Jar.object({
    'email': Jar.string().email('Invalid email').required('Email is required'),
    'password': Jar.string()
      .min(6, 'Password must be at least 6 characters')
      .required('Password is required'),
  });

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(Map<String, dynamic> values) async {
    // Handle login logic
    print('Login with: ${values['email']}');
    
    // Example of handling login API call
    try {
      // await loginService.login(values['email'], values['password']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: JarForm(
          controller: _formController,
          schema: _loginSchema,
          onSubmit: _onSubmit,
          child: Column(
            children: [
              JarFormField<String>(
                name: 'email',
                builder: (state) => TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: state.error,
                  ),
                  onChanged: state.onChange,
                  onTap: state.markAsTouched,
                ),
              ),
              SizedBox(height: 16),
              JarFormField<String>(
                name: 'password',
                builder: (state) => TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: state.error,
                  ),
                  obscureText: true,
                  onChanged: state.onChange,
                  onTap: state.markAsTouched,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _formController.submit();
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Core Components

### JarForm

The main container for your form, which provides the validation context using JAR schemas.

```dart
JarForm(
  controller: formController,
  schema: userSchema,
  onSubmit: (values) {
    // Handle form submission
  },
  child: Column(
    children: [
      // Form fields
    ],
  ),
)
```

### JarFormField

A wrapper for form fields that connects them to the form controller and schema.

```dart
JarFormField<String>(
  name: 'email',
  builder: (state) => TextField(
    decoration: InputDecoration(
      labelText: 'Email',
      errorText: state.error,
    ),
    onChanged: state.onChange,
  ),
)
```

### JarFormController

The core controller that manages form state, validation, and submission.

```dart
final controller = JarFormController();

// Programmatically update field values
controller.setValue('email', 'user@example.com');

// Get current form values
final values = controller.getValues();

// Check form state
if (controller.isValid) {
  // Form is valid
}

// Submit the form
controller.submit(onSubmit);
```

## JarFieldState Properties

The `JarFieldState` object provides access to field state and actions:

- `value` - The current field value
- `error` - The current validation error message (if any)
- `isDirty` - Whether the field has been modified
- `isTouched` - Whether the field has been touched by the user
- `isValidating` - Whether async validation is in progress
- `isDisabled` - Whether the field is disabled
- `onChange(value)` - Update the field value
- `markAsTouched()` - Mark the field as touched

## Advanced Usage

### Async Validation

```dart
JarFieldConfig<String>(
  schema: Jar.string().email().required(),
  asyncValidators: [
    (value) async {
      if (value == null) return null;
      
      // Check if email is already registered
      final isRegistered = await userService.checkEmailExists(value);
      return isRegistered ? 'Email already registered' : null;
    },
  ],
)
```

### Conditional Fields

```dart
JarForm(
  controller: _formController,
  schema: Jar.object({
    'paymentType': Jar.string().oneOf(['credit', 'paypal']).required(),
    'cardNumber': Jar.string().when('paymentType', {
      'credit': (schema) => schema.required(),
      'paypal': (schema) => schema.optional(),
    }),
  }),
  child: Column(
    children: [
      JarFormField<String>(
        name: 'paymentType',
        builder: (state) => /* payment type selector */,
      ),
      
      JarFormField<String>(
        name: 'cardNumber',
        builder: (state) {
          // Only show when payment type is credit
          if (_formController.getFieldValue('paymentType') != 'credit') {
            return SizedBox.shrink();
          }
          
          return TextField(
            decoration: InputDecoration(
              labelText: 'Card Number',
              errorText: state.error,
            ),
            onChanged: state.onChange,
          );
        },
      ),
    ],
  ),
)
```

### Field Watching

```dart
@override
void initState() {
  super.initState();
  
  // Watch for changes to a field
  _formController.watch<String>('username', (value) {
    // React to changes
    print('Username changed to: $value');
  });
}

@override
void dispose() {
  // Optional: Unwatch when component is disposed
  _formController.unwatch<String>('username', _onUsernameChange);
  super.dispose();
}
```

### Reset and Clear

```dart
// Reset a specific field to its default value
_formController.reset('email');

// Reset the entire form
_formController.resetAll();

// Clear a specific field (set to null)
_formController.clear('email');

// Clear all fields
_formController.clearAll();
```

### Enable/Disable Fields

```dart
// Disable a field
_formController.disable('email');

// Enable a field
_formController.enable('email');
```

## Advantages of JAR Form

- **Type Safety**: Fully typed form controls for compile-time checks
- **Performance**: Optimized rendering that updates only changed fields
- **Separation of Concerns**: Clean separation between UI, validation, and form state
- **Flexibility**: Works with any Flutter widget for custom form UIs
- **Integration**: Seamless integration with JAR validation schemas
- **Testing**: Easy to test with predictable state management

## License

JAR Form is available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Contributors

[Julian Ramirez](https://github.com/julianramireze)