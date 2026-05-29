import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { parseFile } from './parser';
import { transformFile } from './transformer';

export function activate(context: vscode.ExtensionContext) {
  const command = vscode.commands.registerCommand(
    'sqflow.convertToModel',
    async (uri?: vscode.Uri) => {
      try {
        // Resolve file URI: from context menu (uri) or active editor
        const fileUri = uri ?? vscode.window.activeTextEditor?.document.uri;
        if (!fileUri) {
          vscode.window.showErrorMessage('SQFlow: No Dart file selected.');
          return;
        }

        // Ensure it's a .dart file
        if (!fileUri.fsPath.endsWith('.dart')) {
          vscode.window.showErrorMessage('SQFlow: Only .dart files are supported.');
          return;
        }

        // Read source
        const sourceBytes = fs.readFileSync(fileUri.fsPath);
        const source = sourceBytes.toString('utf8');

        // Derive file name without extension (e.g. "user" from "user.dart")
        const fileName = path.basename(fileUri.fsPath, '.dart');

        // Parse
        const parsed = parseFile(source, fileName);

        if (parsed.classes.length === 0) {
          vscode.window.showWarningMessage('SQFlow: No Dart classes found in this file.');
          return;
        }

        const unconverted = parsed.classes.filter(c => !c.alreadyConverted);
        if (unconverted.length === 0) {
          vscode.window.showInformationMessage(
            'SQFlow: All classes in this file are already SQFlow models.'
          );
          return;
        }

        // Transform
        const newSource = transformFile(parsed);

        // Write back
        fs.writeFileSync(fileUri.fsPath, newSource, 'utf8');

        // Open/refresh the document in VS Code
        const doc = await vscode.workspace.openTextDocument(fileUri);
        await vscode.window.showTextDocument(doc);

        // Format document if Dart formatter is available
        await vscode.commands.executeCommand(
          'editor.action.formatDocument'
        ).then(
          () => {},
          () => {} // Ignore if formatter not available
        );

        const classNames = unconverted.map(c => c.name).join(', ');
        vscode.window.showInformationMessage(
          `✅ SQFlow: Converted ${unconverted.length} class(es): ${classNames}`
        );
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        vscode.window.showErrorMessage(`SQFlow: Error — ${message}`);
        console.error('[sqflow-dart]', err);
      }
    }
  );

  context.subscriptions.push(command);
}

export function deactivate() {}
