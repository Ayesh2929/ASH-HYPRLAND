"""Legacy per-resource endpoint modules.

The v1 API is implemented in ``api/routes.py`` as a single auditable router.
These modules remain as thin re-exports so early integrations that imported
``api.endpoints.theme`` keep working.
"""
