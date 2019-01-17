import Foundation
import PackageConfig
import ShellOut

// To emulate running the command as the script woudl do:
//
// swift run komondor run [hook-name]
//
//
public func runner(logger _: Logger, args: [String]) throws {
    let pkgConfig = getPackageConfig()

    guard let hook = args.first else {
        logger.logError("[Komondor] The runner was called without a hook")
        exit(1)
    }

    guard let config = pkgConfig["komondor"] else {
        logger.logError("[Komondor] Could not find komondor settings inside the Package.swift")
        exit(1)
    }

    guard let hookOptions = config[hook] else {
        logger.logError("[Komondor] Could not find a key for '\(hook)' under the komondor settings'")
        exit(1)
    }

    var commands = [] as [String]
    if let stringOption = hookOptions as? String {
        commands = [stringOption]
    } else if let arrayOptions = hookOptions as? [String] {
        commands = arrayOptions
    }

    logger.debug("Running commands for komondor \(commands.joined())")

    var failedCommands = [] as [String]
    var executedCommand = ""
    do {
        try commands.forEach { command in
            executedCommand = command
            print("> \(command)")
            // Simple is fine for now
            try shellOut(to: command)

            // Ideal:
            //   Store STDOUT and STDERR, and only show it if it fails
            //   Show a stepper like system of all commands
        }
    } catch {
        guard let error = error as? ShellOutError else { return }
        print(error.message) // Prints STDERR
        print(error.output) // Prints STDOUT
        failedCommands.append(executedCommand)
    }

    guard failedCommands.isEmpty else {
        logger.logError("[Komondor] The following commands failed to execute: \(failedCommands.joined())")
        exit(1)
    }
}
