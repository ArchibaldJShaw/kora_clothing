-- Schema bootstrap for playerskins/playeroutfits: the tables are declared in
-- server/schema.lua and applied through kora_sql's declarative schema handler.

KoraClothing = KoraClothing or {}
local P = {}
KoraClothing.persistence = P

local state = { ready = false, lastError = nil }

function P.ready()
    return state.ready
end

local function bootstrap()
    local sqlReady, readyErr = Kora.sql.ready(60000)
    if not sqlReady then
        state.lastError = readyErr or 'kora_sql did not become ready'
        Kora.logging.error('schema.sql_unavailable', 'kora_sql did not become ready', { error = tostring(state.lastError) })
        return
    end

    local reports, schemaErr = Kora.sql.ensureTables(KoraClothingSchema)
    if schemaErr then
        state.lastError = schemaErr
        Kora.logging.error('schema.setup_failed', 'Schema setup failed', { error = tostring(schemaErr) })
        return
    end
    for _, report in ipairs(reports or {}) do
        for _, warning in ipairs(report.warnings or {}) do
            Kora.logging.warn('schema.warning', 'Schema reported a warning', { table = tostring(report.table), warning = tostring(warning) })
        end
    end

    state.ready = true
    Kora.logging.info('schema.ready', 'playerskins/playeroutfits schema ready')
    TriggerEvent('kora_clothing:server:persistenceReady')
end

CreateThread(bootstrap)
