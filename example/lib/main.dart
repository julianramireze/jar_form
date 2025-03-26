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
      home: FormExample(),
    );
  }
}

class FormExample extends StatefulWidget {
  @override
  _FormExampleState createState() => _FormExampleState();
}

class _FormExampleState extends State<FormExample> {
  final _formController = JarFormController();
  bool _showPaymentFields = false;

  @override
  void initState() {
    super.initState();

    final formSchema = Jar.object({
      'name': Jar.string().required('Name is required'),
      'email':
          Jar.string().email('Invalid email').required('Email is required'),
      'paymentMethod': Jar.string().oneOf(
          ['creditCard', 'bankTransfer', 'paypal'],
          'Invalid payment method').required('Payment method is required'),
    });

    _formController.register(
        'name',
        JarFieldConfig(
            schema: formSchema.fields['name']
                as JarSchema<dynamic, JarSchema<dynamic, dynamic>>));
    _formController.register(
        'email',
        JarFieldConfig(
            schema: formSchema.fields['email']
                as JarSchema<dynamic, JarSchema<dynamic, dynamic>>));
    _formController.register(
        'paymentMethod',
        JarFieldConfig(
            schema: formSchema.fields['paymentMethod']
                as JarSchema<dynamic, JarSchema<dynamic, dynamic>>));

    String? validateCreditCard(String? value,
        [Map<String, dynamic>? allValues]) {
      final method = allValues?['paymentMethod'];
      if (method == 'creditCard' && (value == null || value.isEmpty)) {
        return 'Credit card number is required for credit card payments';
      }
      return null;
    }

    _formController.register(
        'creditCardNumber',
        JarFieldConfig<String>(
            schema: Jar.string().custom(validateCreditCard)
                as JarSchema<String, JarSchema<String, dynamic>>));

    _formController.watch<String>('paymentMethod', (value) {
      setState(() {
        _showPaymentFields = value == 'creditCard';
      });

      _formController.trigger(['creditCardNumber']);
    });

    _formController.addListener(_onFormControllerChange);
  }

  void _onFormControllerChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _formController.removeListener(_onFormControllerChange);
    _formController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(Map<String, dynamic> values) async {
    await Future.delayed(const Duration(seconds: 1));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Form submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    print('Form values:');
    print(values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JAR Form - Dependent Validation Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: JarForm(
          controller: _formController,
          schema: Jar.object({}),
          onSubmit: _onSubmit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JarFormField<String>(
                name: 'name',
                builder: (state) => TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: state.error,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: state.onChange,
                  onTap: state.markAsTouched,
                ),
              ),
              SizedBox(height: 16),
              JarFormField<String>(
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
              ),
              SizedBox(height: 16),
              JarFormField<String>(
                name: 'paymentMethod',
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        errorText: state.error,
                        border: OutlineInputBorder(),
                      ),
                      value: state.value,
                      hint: Text('Select payment method'),
                      items: [
                        DropdownMenuItem(
                            value: 'creditCard', child: Text('Credit Card')),
                        DropdownMenuItem(
                            value: 'bankTransfer',
                            child: Text('Bank Transfer')),
                        DropdownMenuItem(
                            value: 'paypal', child: Text('PayPal')),
                      ],
                      onChanged: (value) {
                        state.onChange(value);
                        state.markAsTouched();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (_showPaymentFields)
                JarFormField<String>(
                  name: 'creditCardNumber',
                  builder: (state) => TextField(
                    decoration: InputDecoration(
                      labelText: 'Credit Card Number',
                      errorText: state.error,
                      border: OutlineInputBorder(),
                      helperText: 'Required for credit card payments',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: state.onChange,
                    onTap: state.markAsTouched,
                  ),
                ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _formController.submit();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Submit',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _formController.resetAll();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Reset',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildFormStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form Status:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            _buildStatusRow('Valid', _formController.isValid),
            _buildStatusRow('Dirty', _formController.isDirty),
            _buildStatusRow('Touched', _formController.isTouched),
            _buildStatusRow('Submitting', _formController.isSubmitting),
            SizedBox(height: 16),
            Text('Form Values:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              _formController.getValues().toString(),
              style: TextStyle(fontFamily: 'monospace'),
            ),
            SizedBox(height: 16),
            Text('Form Errors:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              _formController.getErrors().toString(),
              style: TextStyle(fontFamily: 'monospace', color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 18,
          ),
          SizedBox(width: 4),
          Text(value.toString()),
        ],
      ),
    );
  }
}
