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
      title: 'JAR Form Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SignupScreen(),
    );
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formController = JarFormController();

  final _signupSchema = Jar.object({
    'username': Jar.string()
        .min(3, 'Username must be at least 3 characters')
        .max(20, 'Username cannot exceed 20 characters')
        .required('Username is required'),
    'email': Jar.string()
        .email('Invalid email format')
        .required('Email is required'),
    'password': Jar.string()
        .min(8, 'Password must be at least 8 characters')
        .matches(
          r'(?=.*[A-Z])',
          'Password must contain at least one uppercase letter',
        )
        .required('Password is required'),
    'confirmPassword': Jar.string().required('Please confirm your password'),
    'age': Jar.number()
        .min(18, 'You must be at least 18 years old')
        .required('Age is required'),
    'termsAccepted': Jar.boolean()
        .isTrue('You must accept the terms and conditions')
        .required('Please respond to the terms'),
  });

  @override
  void initState() {
    super.initState();

    // Add custom validation for confirmPassword
    _formController.watch<String>('password', (_) {
      // Trigger validation on confirmPassword when password changes
      _formController.trigger('confirmPassword');
    });
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(Map<String, dynamic> values) async {
    // Check if password and confirmPassword match
    if (values['password'] != values['confirmPassword']) {
      _formController.setValue<String>(
        'confirmPassword',
        values['confirmPassword'],
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signup successful!')),
    );

    // In a real app, you would send the data to your API
    print('Form submitted with values:');
    print(values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup Example'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: JarForm(
          controller: _formController,
          schema: _signupSchema,
          onSubmit: _onSubmit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUsernameField(),
              SizedBox(height: 16),
              _buildEmailField(),
              SizedBox(height: 16),
              _buildPasswordField(),
              SizedBox(height: 16),
              _buildConfirmPasswordField(),
              SizedBox(height: 16),
              _buildAgeField(),
              SizedBox(height: 16),
              _buildTermsField(),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _formController.submit();
                },
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return JarFormField<String>(
      name: 'username',
      builder: (state) => TextField(
        decoration: InputDecoration(
          labelText: 'Username',
          errorText: state.error,
          border: OutlineInputBorder(),
        ),
        onChanged: state.onChange,
        onTap: state.markAsTouched,
      ),
    );
  }

  Widget _buildEmailField() {
    return JarFormField<String>(
      name: 'email',
      builder: (state) => TextField(
        decoration: InputDecoration(
          labelText: 'Email',
          errorText: state.error,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        onChanged: state.onChange,
        onTap: state.markAsTouched,
      ),
    );
  }

  Widget _buildPasswordField() {
    return JarFormField<String>(
      name: 'password',
      builder: (state) => TextField(
        decoration: InputDecoration(
          labelText: 'Password',
          errorText: state.error,
          border: OutlineInputBorder(),
        ),
        obscureText: true,
        onChanged: state.onChange,
        onTap: state.markAsTouched,
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return JarFormField<String>(
      name: 'confirmPassword',
      builder: (state) {
        // Add custom validation for password matching
        final password = _formController.getFieldValue<String>('password');
        if (state.value != null &&
            password != null &&
            state.value != password &&
            state.error == null) {
          // Una mejor solución es crear un validador asincrónico personalizado
          // que podemos adjuntar al campo al registrarlo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Simplemente actualiza el valor, lo que disparará la validación
            // En una app real, añadiríamos validación personalizada al schema o
            // a través de asyncValidators
            _formController.setValue('confirmPassword', state.value);

            // Simulamos un pequeño retraso para permitir que la validación se complete
            Future.delayed(Duration(milliseconds: 50), () {
              // Y luego simplemente comparamos de nuevo y mostramos un SnackBar o similar
              final password =
                  _formController.getFieldValue<String>('password');
              final confirm =
                  _formController.getFieldValue<String>('confirmPassword');
              if (password != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
              }
            });
          });
        }

        return TextField(
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            errorText: state.error,
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          onChanged: state.onChange,
          onTap: state.markAsTouched,
        );
      },
    );
  }

  Widget _buildAgeField() {
    return JarFormField<num>(
      name: 'age',
      builder: (state) => TextField(
        decoration: InputDecoration(
          labelText: 'Age',
          errorText: state.error,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          if (value.isEmpty) {
            state.onChange(null);
          } else {
            state.onChange(int.tryParse(value));
          }
        },
        onTap: state.markAsTouched,
      ),
    );
  }

  Widget _buildTermsField() {
    return JarFormField<bool>(
      name: 'termsAccepted',
      builder: (state) => CheckboxListTile(
        title: Text('I accept the terms and conditions'),
        value: state.value ?? false,
        onChanged: (value) {
          state.onChange(value);
          state.markAsTouched();
        },
        controlAffinity: ListTileControlAffinity.leading,
        subtitle: state.error != null
            ? Text(
                state.error!,
                style: TextStyle(color: Colors.red),
              )
            : null,
      ),
    );
  }
}
