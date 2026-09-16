# Salesforce Sync Jobs

## Parent-Sync Race Guard
- Before saving a child record that uses a `__r__` external-ID lookup, call `ensure_parent_synced!(model, external_id_field, external_id, label)` on the `Salesforce::SalesforceSyncJob` base class.
- The guard must confirm that the parent has a non-nil `sfid` in its Heroku Connect mirror. If it does not, raise `SalesforceRecordNotFound`.
- This guard is required because Heroku Connect permanently rejects the child INSERT with `Foreign key external ID … not found` when the parent has not reached Salesforce. The failed mirror row is not retried automatically.
- Let the base job's `retry_on SalesforceRecordNotFound, wait: :polynomially_longer, attempts: 10` retry the child after its parent lands.
- Follow `Salesforce::RoleSyncJob` and `Salesforce::ClassTeacherSyncJob` as call-site examples.
