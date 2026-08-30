import { Link } from 'react-router-dom';

import {
  domain,
  version,
  statusPageUrl,
  profile_directory as canProfileDirectory,
  termsOfServiceEnabled,
} from 'mastodon/initial_state';

import classes from './link_footer.module.scss';

const DONATE_URL = 'https://donate.nofan.xyz/';
const ROADMAP_URL = 'https://roadmap.nofan.xyz/';

export const LinkFooter: React.FC<{
  context?: 'default' | 'multi-column' | 'about';
}> = ({ context = 'default' }) => {
  const multiColumn = context === 'multi-column';

  return (
    <footer className={classes.wrapper} data-context={context}>
      <ul className={classes.list}>
        <li>
          <Link to='/about' target={multiColumn ? '_blank' : undefined}>
            About
            <span className='sr-only'> {domain}</span>
          </Link>
        </li>
        <li>
          <a href={DONATE_URL} target='_blank' rel='noopener'>
            Donate
          </a>
        </li>
        <li>
          <a href={ROADMAP_URL} target='_blank' rel='noopener'>
            Roadmap
          </a>
        </li>
        {statusPageUrl && (
          <li>
            <a href={statusPageUrl} target='_blank' rel='noopener'>
              Status
            </a>
          </li>
        )}
        {canProfileDirectory && (
          <li>
            <Link to='/directory'>Profiles directory</Link>
          </li>
        )}
        {termsOfServiceEnabled && (
          <li>
            <Link
              to='/terms-of-service'
              target={multiColumn ? '_blank' : undefined}
              rel='terms-of-service'
            >
              Terms of service
            </Link>
          </li>
        )}
        <li className={classes.version}>v{version}</li>
      </ul>
    </footer>
  );
};
