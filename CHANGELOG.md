# Changelog

## 1.0.3

### Changes

- Reverted cross-field validation changes from 1.0.2 due to issues
- Restored stable functionality from 1.0.1

## 1.0.2

**DEPRECATED** - Please use 1.0.3 instead

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
