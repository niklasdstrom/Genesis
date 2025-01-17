import GenesisKit
import PathKit
import XCTest

public class TemplateTests: XCTestCase {

    func testTemplateParsing() throws {
        let templateFixture = fixturePath + "template.yml"
        let parsedTemplate = try GenesisTemplate(path: templateFixture)

        let expectedFiles: [File] = [
            File(type: .template("Project.stencil"), path: "{{ project }}.swift"),
            File(type: .contents("File {{ name }} of type {{ type }}"), path: "{{ name }}.{{ type }}", include: "generate", context: "files"),
            File(type: .directory, path: "{{ path }}/Grandchild"),
            File(type: .contents("### Hello"), path: "README.md"),
            File(type: .copy("folder"), path: "folder"),
            File(type: .copy("folder2"), path: "new folder"),
        ]
        let expectedOptions: [Option] = [
            Option(name: "project", description: "The name of the project", value: "Project", type: .string, question: "What is the name of your project?", required: true),
            Option(name: "files", description: "The list of files", type: .array, question: "Do you wish to add a file?", options: [
                Option(name: "name", question: "What's the name of the file?"),
                Option(name: "type", type: .choice, question: "What sort of file?", choices: ["stencil", "swift"]),
                Option(name: "generate", value: "true", type: .boolean, question: "Should this be generated?"),
            ]),
            Option(name: "path", description: "The name of the path to App directory", value: "Parent/Child", type: .string, question: "What is the name of the path for App directory?", required: true),
        ]
        let expectedTemplate = GenesisTemplate(
            path: templateFixture,
            section: TemplateSection(files: expectedFiles, options: expectedOptions)
        )

        XCTAssertEqual(expectedTemplate, parsedTemplate)
    }
}
