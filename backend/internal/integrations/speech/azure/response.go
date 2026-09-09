// integrations/speech/azure: private structs mirroring Azure's JSON exactly.
//
// EVERY TYPE IN THIS FILE IS UNEXPORTED, deliberately. Go's visibility rules then make it
// impossible for any other package to reference an Azure field, so vendor coupling cannot
// leak by accident rather than merely by convention.
//
// Nothing here is ever stored, returned to the app, or passed to business logic.
//
// See ARCHITECTURE.md 7.2, 7.4.

package azure
