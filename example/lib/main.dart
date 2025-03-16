import 'package:flutter/material.dart';
import 'package:jar/jar.dart';
import 'package:jar_form/controller.dart';
import 'package:jar_form/field.dart';
import 'package:jar_form/field/config.dart';
import 'package:jar_form/form.dart';

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
  late final JarObject _signupSchema;

  final _asyncUsernameValidator = (dynamic value) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return value == 'admin' ? 'Username already taken' : null;
  };

  @override
  void initState() {
    super.initState();

    _signupSchema = Jar.object({
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
      'confirmPassword': Jar.string()
          .equalTo('password', 'Passwords must match')
          .required('Please confirm your password'),
      'age': Jar.number()
          .min(18, 'You must be at least 18 years old')
          .required('Age is required'),
      'termsAccepted': Jar.boolean()
          .isTrue('You must accept the terms and conditions')
          .required('Please respond to the terms'),
    });

    _formController.register(
      'username',
      JarFieldConfig<String>(
        schema: _signupSchema.fields['username']
            as JarSchema<String, JarSchema<String, dynamic>>,
        asyncValidators: [_asyncUsernameValidator],
      ),
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(Map<String, dynamic> values) async {
    await Future.delayed(const Duration(seconds: 1));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signup successful!'),
        backgroundColor: Colors.green,
      ),
    );

    print('Form submitted with values:');
    print(values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JAR Form Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: JarForm(
          controller: _formController,
          schema: _signupSchema,
          onSubmit: _onSubmit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
              const SizedBox(height: 16),
              _buildAgeField(),
              const SizedBox(height: 16),
              _buildTermsField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildResetButton(),
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
        //should pass value for maintain sync when value changes
        decoration: InputDecoration(
          labelText: 'Username',
          errorText: state.error,
          border: const OutlineInputBorder(),
          helperText: 'Try "admin" to see async validation error',
          suffixIcon: state.isValidating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.0))
              : null,
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
        //should pass value for maintain sync when value changes
        decoration: InputDecoration(
          labelText: 'Email',
          errorText: state.error,
          border: const OutlineInputBorder(),
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
        //should pass value for maintain sync when value changes
        decoration: InputDecoration(
          labelText: 'Password',
          errorText: state.error,
          border: const OutlineInputBorder(),
          helperText: 'Must be at least 8 characters with 1 uppercase letter',
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
      builder: (state) => TextField(
        //should pass value for maintain sync when value changes
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          errorText: state.error,
          border: const OutlineInputBorder(),
        ),
        obscureText: true,
        onChanged: state.onChange,
        onTap: state.markAsTouched,
      ),
    );
  }

  Widget _buildAgeField() {
    return JarFormField<num>(
      name: 'age',
      builder: (state) => TextField(
        //should pass value for maintain sync when value changes
        decoration: InputDecoration(
          labelText: 'Age',
          errorText: state.error,
          border: const OutlineInputBorder(),
          helperText: 'You must be at least 18 years old',
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
        title: const Text('I accept the terms and conditions'),
        value: state.value ?? false,
        onChanged: (value) {
          state.onChange(value);
          state.markAsTouched();
        },
        controlAffinity: ListTileControlAffinity.leading,
        subtitle: state.error != null
            ? Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              )
            : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Builder(builder: (context) {
      return ElevatedButton(
        onPressed: _formController.isSubmitting
            ? null
            : () => _formController.submit(),
        child: _formController.isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.0, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text('Submitting...'),
                ],
              )
            : const Text('Sign Up'),
      );
    });
  }

  Widget _buildResetButton() {
    return OutlinedButton(
      onPressed: () => _formController.clearAll(),
      child: const Text('Reset Form'),
    );
  }
}
