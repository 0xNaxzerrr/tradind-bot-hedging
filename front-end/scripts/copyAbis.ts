// frontend/scripts/copyAbis.ts
import fs from 'fs';
import path from 'path';

const sourceDir = '../out';
const targetDir = './src/abis';

// Assurez-vous que le dossier cible existe
if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
}

// Copier les fichiers ABI
fs.readdirSync(sourceDir).forEach(file => {
    if (file.endsWith('.json')) {
        const sourcePath = path.join(sourceDir, file);
        const targetPath = path.join(targetDir, file);
        const content = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
        
        // Ne copier que l'ABI
        const abiOnly = {
            abi: content.abi,
            contractName: content.contractName
        };
        
        fs.writeFileSync(targetPath, JSON.stringify(abiOnly, null, 2));
    }
});