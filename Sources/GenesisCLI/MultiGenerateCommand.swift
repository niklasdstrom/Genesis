
import Foundation
import GenesisKit
import PathKit
import SwiftCLI
import Yams

class MultiGenerateCommand: Command {
    
    let name = "multigenerate"
    let shortDescription = "Generates multiple files from a yaml template."

    let templatePath = Param<String>()

    let optionsArgument = Key<String>("-t", "--templates", description: "Provide templates for each root type --templates \"project: template/project.yml, apps: template/app.yml")
    
    let stream: Streams

    init(stream: Streams) {
        self.stream = stream
    }
    
    
    func execute() throws {
        
        let templatePath = Path(self.templatePath.value).absolute()
        
        var templates: [String:String] = [:]

        if !templatePath.exists {
            stream.out <<< "Template path \(templatePath) doesn't exist"
            exit(1)
        }
        let string: String = try templatePath.read()
        
        guard let dictionary = try Yams.load(yaml: string) as? [String: Any] else {
            stream.out <<< "Option path decoding failed"
            exit(1)
        }
        
        if let commandLineOptions = optionsArgument.value {
            let optionList: [String] = commandLineOptions
                .split(separator: ",")
                .map(String.init)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            let optionPairs: [(String, String)] = optionList
                .map { option in
                    option
                        .split(separator: ":")
                        .map(String.init)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                .filter { $0.count == 2 }
                .map { ($0[0], $0[1]) }

            for (key, value) in optionPairs {
                templates[key] = value
            }
        }
        
        var destinationPaths: [String] = []
        
        let relativeFolder = templatePath.parent()
        
        for (type, targets) in dictionary {
            
            guard let pathValue = templates[type.lowercased()] else {
                stream.out <<< "Template missing for \(type)"
                exit(1)
            }
            
            let path = Path(pathValue).absolute()
                
            if !path.exists {
                stream.out <<< "Template path \(path) doesn't exist"
                exit(1)
            }
            
            guard let targets = targets as? [String: [String: Any]] else {
                stream.out <<< "Invalid configuration"
                exit(1)
            }
            
            let template = try GenesisTemplate(path: path)
            let generator = try TemplateGenerator(template: template)
            
            for (target, options) in targets {
                
                guard let destination = options["destination"] as? String else {
                    stream.out <<< "\(target) is missing destination"
                    exit(1)
                }
                
                let destinationPath = relativeFolder + Path(destination)
                
                var context = options
                context.removeValue(forKey: "destination")
                
                // target added as name by default
                context["name"] = target
                
                let result = try generator.generate(context: context, interactive: false)
                try result.writeFiles(path: destinationPath)

                destinationPaths.append(contentsOf: result.files.map { $0.path.absolute().string })
            }
        }
        
        stream.out <<< destinationPaths.joined(separator: ", ")
    }
    
}
