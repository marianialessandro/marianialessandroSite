// Configure these non-secret Action secrets from verified tenant metadata before deploying the Action.
exports.onExecutePostLogin = async (event, api) => {
    if (event.resource_server?.identifier !== event.secrets.MCP_RESOURCE) {
        return;
    }
    if (event.user.user_id !== event.secrets.MCP_ALLOWED_SUBJECT) {
        api.access.deny('Accesso non autorizzato.');
        return;
    }
    api.accessToken.setCustomClaim('https://mcp.marianialessandro.com/token_use', 'access');
};
