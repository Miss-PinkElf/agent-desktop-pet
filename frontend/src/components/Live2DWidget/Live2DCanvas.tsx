import { useEffect, useRef, useState } from 'react';
import * as PIXI from 'pixi.js';

type Live2DCanvasProps = {
  width?: number;
  height?: number;
  onAppReady?: (app: PIXI.Application | null) => void;
};

export default function Live2DCanvas({
  width = 600,
  height = 750,
  onAppReady,
}: Live2DCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [app, setApp] = useState<PIXI.Application | null>(null);
  const initializedRef = useRef(false);

  useEffect(() => {
    if (!canvasRef.current || initializedRef.current) return;
    initializedRef.current = true;

    const pixiApp = new PIXI.Application({
      view: canvasRef.current,
      width,
      height,
      backgroundAlpha: 0,
      resolution: window.devicePixelRatio * 2 || 2,
      autoDensity: true,
      antialias: true,
    });

    setApp(pixiApp);
    onAppReady?.(pixiApp);

    return () => {
      pixiApp.destroy(true);
      setApp(null);
      onAppReady?.(null);
      initializedRef.current = false;
    };
  }, [height, onAppReady, width]);

  useEffect(() => {
    if (!app) return;
    app.renderer.resize(width, height);
  }, [app, height, width]);

  return <canvas className="live2d-canvas" ref={canvasRef} />;
}
