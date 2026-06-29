# Changelog

## 1.1.0

### Features

- Added `JarFieldArray`, a first-class widget for repeatable subforms (the Flutter equivalent of react-hook-form's `useFieldArray`)
- Each item exposes a stable `id` (for widget keys) and an `index`, with `item.path('field')` resolving to the namespaced leaf name (e.g. `professions.0.startTime`)
- Array operations on the builder handle: `append`, `insert`, `removeAt`, `move`, `clear`, plus `items`, `length`, and array-level `error`
- Array-level rules (`min`/`max`/`unique`) and per-element validation are delegated to JAR's `JarArray` schema
- `getValues()` now returns array data as a clean nested list (e.g. `{'professions': [ {...}, {...} ]}`) instead of flattened keys

### Changes

- `JarFormController` gained `registerArray`, `getArray`, and `unregister`
- `JarFormField` now re-subscribes when its `name` changes, keeping bindings correct as array items are reordered or removed

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
