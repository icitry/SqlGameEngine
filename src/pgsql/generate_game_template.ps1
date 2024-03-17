param(
    [string]$path = '.',
    [string]$gameName
)

$gameNamePath = $gameName -replace '\s', '_' -replace '\W', '_' -replace '__+', '_'
$gameNamePath = $gameNamePath.ToLower()

$filePath = Join-Path -Path $path -ChildPath "$gameNamePath.sql"
$absoluteFilePath = (Resolve-Path -Path $path).Path

$content = @"
-- Generated template for $gameName.
-- Make use of the provided functions to build your game.
-- Once done, use ** \i `"$absoluteFilePath`" ** to load your game into the database.
-- Afterwards, call ** select start_game(<env_id>); ** with the id of the desired configuration.

CREATE OR REPLACE FUNCTION on_init()
RETURNS void AS `$`$
BEGIN
    -- Runs before the game loop begins.
END;
`$`$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION on_input_event(input_event_type INTEGER, key_code INTEGER)
RETURNS void AS `$`$
BEGIN
    -- Handle user event here.
END;
`$`$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION on_render_frame()
RETURNS void AS `$`$
BEGIN
    -- Render frame here.
END;
`$`$ LANGUAGE plpgsql;
"@

$content | Out-File -FilePath $filePath -Force

Write-Host "Generated game template at: $filePath"