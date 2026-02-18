import { useEffect, useState } from 'react';
import * as PIXI from 'pixi.js';
import { Live2DModel } from 'pixi-live2d-display/cubism4';

Live2DModel.registerTicker(PIXI.Ticker);

export function useLive2DModel(app: PIXI.Application | null) {
  const [model, setModel] = useState<Live2DModel | null>(null);

  useEffect(() => {
    if (!app) return;
    let disposed = false;
    let live2dModel: Live2DModel | null = null;

    const loadModel = async () => {
      live2dModel = await Live2DModel.from('/jk-cat/jk盐.model3.json');

      if (disposed || !live2dModel) return;

      app.stage.addChild(live2dModel);
      app.stage.interactive = true;
      app.stage.hitArea = app.screen;
      live2dModel.interactive = true;

      live2dModel.anchor.set(0.5, 0.5);

      const scale = Math.min(
        app.screen.width / live2dModel.width,
        app.screen.height / live2dModel.height,
      );
      live2dModel.scale.set(scale * 0.9);

      live2dModel.x = app.screen.width / 2;
      live2dModel.y = app.screen.height / 2;

      setModel(live2dModel);
    };

    loadModel();

    return () => {
      disposed = true;
      if (live2dModel) {
        app.stage.removeChild(live2dModel);
        live2dModel.destroy();
      }
      setModel(null);
    };
  }, [app]);

  return model;
}
