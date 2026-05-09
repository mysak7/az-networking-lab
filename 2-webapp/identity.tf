# Backend App Service can read/write blobs directly via managed identity (no connection string needed)
resource "azurerm_role_assignment" "backend_storage_blob" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.backend.identity[0].principal_id
}
