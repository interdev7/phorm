import * as vscode from 'vscode';
import * as path from 'path';
import { parseFile } from './parser';
import { transformFile, TransformOptions } from './transformer';

/**
 * Reads transform options from the user's workspace configuration.
 */
function readOptions(): TransformOptions {
  const cfg = vscode.workspace.getConfiguration('phorm');
  return {
    generateFullService: cfg.get<boolean>('generateFullService', true),
    timestamps: cfg.get<boolean>('timestamps', true),
    paranoid: cfg.get<boolean>('paranoid', false),
    addFromJson: cfg.get<boolean>('addFromJson', true),
  };
}

/**
 * Converts a Dart document to PHORM models and applies the change through an
 * undoable WorkspaceEdit. Returns the names of converted classes (empty if
 * there was nothing to do).
 */
async function convertDocument(
  document: vscode.TextDocument,
  targetClassName?: string
): Promise<string[]> {
  const source = document.getText();
  const fileName = path.basename(document.uri.fsPath, '.dart');

  const parsed = parseFile(source, fileName);

  if (parsed.classes.length === 0) {
    vscode.window.showWarningMessage('Phorm: No Dart classes found in this file.');
    return [];
  }

  // When invoked for a single class (e.g. from a CodeLens), restrict the
  // transform to just that class and leave the rest of the file untouched.
  if (targetClassName) {
    parsed.classes = parsed.classes.filter(c => c.name === targetClassName);
  }

  const unconverted = parsed.classes.filter(c => !c.alreadyConverted);
  if (unconverted.length === 0) {
    vscode.window.showInformationMessage(
      'Phorm: All classes in this file are already Phorm models.'
    );
    return [];
  }

  const newSource = transformFile(parsed, readOptions());
  if (newSource === source) {
    return [];
  }

  const edit = new vscode.WorkspaceEdit();
  const fullRange = new vscode.Range(
    document.positionAt(0),
    document.positionAt(source.length)
  );
  edit.replace(document.uri, fullRange, newSource);

  const applied = await vscode.workspace.applyEdit(edit);
  if (!applied) {
    vscode.window.showErrorMessage('Phorm: Failed to apply changes.');
    return [];
  }

  // Best-effort format; ignore if no Dart formatter is installed.
  await vscode.commands.executeCommand('editor.action.formatDocument').then(
    () => {},
    () => {}
  );

  return unconverted.map(c => c.name);
}

async function resolveDocument(uri?: vscode.Uri): Promise<vscode.TextDocument | undefined> {
  if (uri) {
    return vscode.workspace.openTextDocument(uri);
  }
  return vscode.window.activeTextEditor?.document;
}

/**
 * Shows a "⚡ To PHORM Model" action above every plain Dart class that hasn't
 * been converted yet.
 */
class PhormCodeLensProvider implements vscode.CodeLensProvider {
  private readonly onChange = new vscode.EventEmitter<void>();
  readonly onDidChangeCodeLenses = this.onChange.event;

  refresh(): void {
    this.onChange.fire();
  }

  provideCodeLenses(document: vscode.TextDocument): vscode.CodeLens[] {
    if (!vscode.workspace.getConfiguration('phorm').get<boolean>('enableCodeLens', true)) {
      return [];
    }
    const parsed = parseFile(document.getText(), '');
    const lenses: vscode.CodeLens[] = [];
    for (const cls of parsed.classes) {
      if (cls.alreadyConverted) { continue; }
      const pos = document.positionAt(cls.startIndex);
      lenses.push(
        new vscode.CodeLens(new vscode.Range(pos, pos), {
          title: '⚡ To PHORM Model',
          command: 'phorm.convertClass',
          arguments: [document.uri, cls.name],
        })
      );
    }
    return lenses;
  }
}

export function activate(context: vscode.ExtensionContext) {
  const convertCommand = vscode.commands.registerCommand(
    'phorm.convertToModel',
    async (uri?: vscode.Uri) => {
      try {
        const document = await resolveDocument(uri);
        if (!document) {
          vscode.window.showErrorMessage('Phorm: No Dart file selected.');
          return;
        }
        if (!document.uri.fsPath.endsWith('.dart')) {
          vscode.window.showErrorMessage('Phorm: Only .dart files are supported.');
          return;
        }

        await vscode.window.showTextDocument(document);
        const converted = await convertDocument(document);
        if (converted.length > 0) {
          vscode.window.showInformationMessage(
            `✅ Phorm: Converted ${converted.length} class(es): ${converted.join(', ')}`
          );
        }
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        vscode.window.showErrorMessage(`Phorm: Error — ${message}`);
        console.error('[phorm-code]', err);
      }
    }
  );

  const convertClassCommand = vscode.commands.registerCommand(
    'phorm.convertClass',
    async (uri: vscode.Uri, className: string) => {
      try {
        const document = await vscode.workspace.openTextDocument(uri);
        await vscode.window.showTextDocument(document);
        const converted = await convertDocument(document, className);
        if (converted.length > 0) {
          vscode.window.showInformationMessage(
            `✅ Phorm: Converted ${converted.join(', ')}`
          );
        }
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        vscode.window.showErrorMessage(`Phorm: Error — ${message}`);
        console.error('[phorm-code]', err);
      }
    }
  );

  const codeLensProvider = new PhormCodeLensProvider();
  const codeLensRegistration = vscode.languages.registerCodeLensProvider(
    { language: 'dart' },
    codeLensProvider
  );

  const buildRunnerCommand = vscode.commands.registerCommand(
    'phorm.runBuildRunner',
    () => {
      const folder = vscode.workspace.workspaceFolders?.[0];
      const terminal = vscode.window.createTerminal({
        name: 'PHORM build_runner',
        cwd: folder?.uri.fsPath,
      });
      terminal.show();
      terminal.sendText('dart run build_runner build --delete-conflicting-outputs');
    }
  );

  context.subscriptions.push(
    convertCommand,
    convertClassCommand,
    codeLensRegistration,
    buildRunnerCommand
  );
}

export function deactivate() {}
