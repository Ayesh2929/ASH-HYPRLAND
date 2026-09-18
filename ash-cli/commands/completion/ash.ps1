# ASH completion for PowerShell
Register-ArgumentCompleter -Native -CommandName ash -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $commands = @('theme','mode','plugin','snapshot','config','doctor','help','version')
    $subcommands = @{
        theme = @('list','apply','create','delete','edit','export','favorite','history','import','pick','preview','random','reset','schedule','search','validate','wcag')
        mode = @('game','work','focus','cinema','present','battery','stream','privacy','accessibility','default','list','status')
        plugin = @('list','install','remove','enable','disable','search','info')
    }
    $tokens = $commandAst.CommandElements
    if ($tokens.Count -eq 2) {
        $commands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
    } elseif ($tokens.Count -eq 3) {
        $cmd = $tokens[1].Value
        if ($subcommands.ContainsKey($cmd)) {
            $subcommands[$cmd] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        }
    }
}
