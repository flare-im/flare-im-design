import { createRequire } from 'node:module';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(fileURLToPath(new URL('../packages/vue-im-ui/package.json', import.meta.url)));
const ts = require('typescript');

export function publicExports(sourceRoot) {
  const entry = join(sourceRoot, 'index.ts');
  const program = ts.createProgram([entry], {
    noEmit: true, skipLibCheck: true, target: ts.ScriptTarget.ESNext,
    module: ts.ModuleKind.ESNext, moduleResolution: ts.ModuleResolutionKind.Bundler,
  });
  const source = program.getSourceFile(entry);
  const checker = program.getTypeChecker();
  const module = source && checker.getSymbolAtLocation(source);
  if (!module) throw new Error(`Cannot resolve public entry ${entry}`);
  return new Set(checker.getExportsOfModule(module).map(symbol => symbol.name));
}

export function docImports(markdown) {
  const imports = [];
  for (const match of markdown.matchAll(/import\s+(?:type\s+)?\{[^}]+\}\s*from\s*["']@flare-im\/vue-ui["']/g)) {
    const source = ts.createSourceFile('example.ts', match[0], ts.ScriptTarget.Latest, true);
    for (const statement of source.statements) {
      if (!ts.isImportDeclaration(statement)) continue;
      const bindings = statement.importClause?.namedBindings;
      if (bindings && ts.isNamedImports(bindings)) {
        imports.push(...bindings.elements.map(entry => (entry.propertyName ?? entry.name).text));
      }
    }
  }
  return imports;
}
