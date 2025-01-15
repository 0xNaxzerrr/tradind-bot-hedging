import fs from 'fs';
import path from 'path';

const contractsPath = '../out';
const destPath = './abis';

if (!fs.existsSync(destPath)) {
  fs.mkdirSync(destPath);
}

// Copier les ABIs
const contracts = [
  'ImpermanentLossCalculator',
  'TradingBot',
  'PriceCalculator',
  'HedgingStrategy'
];

contracts.forEach(contractName => {
  const sourcePath = path.join(contractsPath, `${contractName}.sol/${contractName}.json`);
  const destFilePath = path.join(destPath, `${contractName}.json`);

  const artifact = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
  const { abi } = artifact;

  fs.writeFileSync(destFilePath, JSON.stringify({ abi }, null, 2));
});