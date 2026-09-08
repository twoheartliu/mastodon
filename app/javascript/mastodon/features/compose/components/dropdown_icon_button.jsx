import PropTypes from 'prop-types';
import { useCallback, useRef, useState } from 'react';

import { DropdownSelector } from 'mastodon/components/dropdown_selector';
import { IconButton } from 'mastodon/components/icon_button';
import { Popover } from 'mastodon/components/popover';

export const DropdownIconButton = ({ value, disabled, icon, onChange, iconComponent, title, options }) => {
  const buttonRef = useRef(null);
  const [open, setOpen] = useState(false);
  const [containerElement, setContainerElement] = useState(null);

  const handleToggle = useCallback(() => {
    setOpen((previousOpen) => !previousOpen);
  }, []);

  const handleClose = useCallback(() => {
    if (open) {
      buttonRef.current?.focus({ preventScroll: true });
    }

    setOpen(false);
  }, [open]);

  return (
    <div ref={setContainerElement}>
      <IconButton
        ref={buttonRef}
        disabled={disabled}
        icon={icon}
        onClick={handleToggle}
        iconComponent={iconComponent}
        title={title}
        active={open}
        expanded={open}
        inverted
      />

      <Popover
        isOpen={open}
        offset={5}
        reference={containerElement}
        onClose={handleClose}
      >
        {({ props, placement }) => (
          <div {...props}>
            <div className={`dropdown-animation privacy-dropdown__dropdown ${placement}`}>
              <DropdownSelector
                items={options}
                value={value}
                onClose={handleClose}
                onChange={onChange}
              />
            </div>
          </div>
        )}
      </Popover>
    </div>
  );
};

DropdownIconButton.propTypes = {
  value: PropTypes.string.isRequired,
  disabled: PropTypes.bool,
  icon: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  iconComponent: PropTypes.func.isRequired,
  options: PropTypes.array.isRequired,
  title: PropTypes.string.isRequired,
};
