import { useEffect, useRef } from 'react';
import { Live2DModel } from 'pixi-live2d-display/cubism4';
import {
  getRandomExpression,
  getRandomInterval,
} from '../../utils/expressionManager';

export function useRandomExpression(model: Live2DModel | null) {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!model) return;

    const playRandomExpression = async () => {
      try {
        const expressionName = getRandomExpression();
        await model.expression(expressionName);
      } catch (error) {
        console.warn('Failed to play expression:', error);
      }

      timerRef.current = setTimeout(playRandomExpression, getRandomInterval());
    };

    timerRef.current = setTimeout(playRandomExpression, getRandomInterval());

    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
      }
    };
  }, [model]);
}
