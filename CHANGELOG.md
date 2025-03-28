# Changelog

## 1.0.2

### Bug Fixes

- Fixed dependent field validation not triggering correctly when related fields change
- Improved cross-field validation to properly validate fields that depend on other field values
- Enhanced revalidation logic to update field state consistently regardless of error changes

## 1.0.1

### Bug Fixes

- Fixed form state not updating properly when using trigger() method
- Ensured consistent notification of form state changes to listeners

## 1.0.0

Initial release.

### Features

- JarForm widget for form management with JAR validation schemas
- JarFormField component for connecting form fields to controller
- JarFormController for managing form state and validation
- Support for synchronous and asynchronous validation
- Form state tracking (dirty, touched, valid, submitting)
- Two-way data binding between form controller and UI
- Field-level validation with error messages
