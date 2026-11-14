-- All published datasets have been registered. Only the actual client's
-- enabled dataset may replace the legacy tables.
local interface = GetBuildInfo and select(4, GetBuildInfo())
AC_Database.Activate(interface, AC_WOWHEAD_DATABASES)
