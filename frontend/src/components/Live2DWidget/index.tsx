import { useState } from 'react';
import * as PIXI from 'pixi.js';
import Live2DCanvas from './Live2DCanvas';
import { useLive2DModel } from './useLive2DModel';
import { useRandomExpression } from './useRandomExpression';
import './index.scss';

export default function Live2DWidget() {
  const [app, setApp] = useState<PIXI.Application | null>(null);
  const model = useLive2DModel(app);

  useRandomExpression(model);

  return (
    <div className="live2d-widget">
      <Live2DCanvas onAppReady={setApp} />
    </div>
  );
}
