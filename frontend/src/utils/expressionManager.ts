const expressionBasePath = '/jk-cat';

const expressionFiles = [
  '脸红.exp3.json',
  '眼-星星眼.exp3.json',
  '眼-爱心眼.exp3.json',
  '眼-哭哭.exp3.json',
  '眼-生气.exp3.json',
  '眼-泪眼汪汪.exp3.json',
  '眼-眩晕流汗.exp3.json',
  '吐舌（也可被ios或vb面捕使用）.exp3.json',
  '脸黑.exp3.json',
  '眼-平静死鱼眼.exp3.json',
];

export function getRandomExpression() {
  const index = Math.floor(Math.random() * expressionFiles.length);
  const fileName = expressionFiles[index];
  return `${expressionBasePath}/${fileName}`;
}

export function getRandomInterval() {
  return 5000 + Math.random() * 5000;
}
