const fs = require('fs');

console.log('Testing directory access...\n');

try {
  const testPath = 'C:\\Users\\Administrator\\.openclaw';
  console.log('Test path:', testPath);

  if (fs.existsSync(testPath)) {
    console.log('✅ Directory exists!');

    const files = fs.readdirSync(testPath);
    console.log('Files:', files.length);
    files.forEach(file => {
      console.log('  -', file);
    });
  } else {
    console.log('❌ Directory does not exist');
  }
} catch (error) {
  console.log('❌ Error:', error.message);
  console.log('Stack:', error.stack);
}
