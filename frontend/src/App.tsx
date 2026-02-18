import Live2DWidget from './components/Live2DWidget';
import styles from './App.module.scss';

export default function App() {
  return (
    <div className={styles.container}>
      <Live2DWidget />
    </div>
  );
}
