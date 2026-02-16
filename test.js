const fs = require('fs');

try {
  const workspaceDir = './.openclaw';
  console.log('Workspace exists:', fs.existsSync(workspaceDir));

  if (fs.existsSync(workspaceDir)) {
    const files = fs.readdirSync(workspaceDir);
    console.log('Files in workspace:', files.length);
    files.forEach(file => {
      console.log('  -', file);
    });
  }
} catch (error) {
  console.error('Error:', error.message);
}
