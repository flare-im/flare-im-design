// @vitest-environment happy-dom
import { mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import FlareMediaUpload from './FlareMediaUpload.vue';
import FlareFileUpload from './FlareFileUpload.vue';
const base = { title: 'Attachments', items: [], statusText: 'Choose or drop files', pickLabel: 'Choose', retryLabel: 'Retry', cancelLabel: 'Cancel', removeLabel: 'Remove', uploadLabel: 'Upload' };
const files = [new File(['a'], 'first.png', {type:'image/png'}), new File(['b'], 'second.pdf', {type:'application/pdf'})];
function drag(element: Element, type: string, batch: File[] = files, types = ['Files']) {
  const event = new Event(type, {bubbles:true,cancelable:true});
  Object.defineProperty(event, 'dataTransfer', {value:{files:batch,types,dropEffect:'none'}});
  element.dispatchEvent(event);
  return event;
}
describe('MediaUpload selection and recovery', () => {
  it('keeps native multi-file selection ordered and allows choosing the same batch again', async () => {
    const wrapper = mount(FlareMediaUpload, {props: base});
    const input = wrapper.get('input[type="file"]').element as HTMLInputElement;
    expect(input.multiple).toBe(true);
    Object.defineProperty(input, 'files', {configurable: true, value: files});
    await wrapper.get('input[type="file"]').trigger('change');
    await wrapper.get('input[type="file"]').trigger('change');
    expect(wrapper.emitted('select')).toEqual([[files], [files]]);
    expect(input.value).toBe('');
    wrapper.unmount();
  });
  it('emits the complete ordered batch from a nested drop zone, without mutating items or truncating', () => {
    const wrapper = mount(FlareMediaUpload, {props:{...base,maxCount:1}});
    const event = drag(wrapper.get('.flare-file-upload').element,'drop');
    expect(event.defaultPrevented).toBe(true);
    expect(wrapper.emitted('select')).toEqual([[files]]);
    expect(wrapper.props('items')).toEqual([]);
    wrapper.unmount();
  });
  it('keeps nested drag highlighting until the full region is left, and clears after drop', async () => {
    const wrapper = mount(FlareMediaUpload,{props:base});
    drag(wrapper.element,'dragenter'); drag(wrapper.get('.flare-file-upload').element,'dragenter');
    drag(wrapper.get('.flare-file-upload').element,'dragleave');
    await wrapper.vm.$nextTick(); expect(wrapper.classes()).toContain('is-dragging');
    drag(wrapper.element,'drop'); await wrapper.vm.$nextTick();
    expect(wrapper.classes()).not.toContain('is-dragging'); wrapper.unmount();
  });
  for (const props of [{disabled:true},{items:[{id:'a',name:'a',state:'uploaded' as const,statusText:'Done'}],maxCount:1}]) {
    it(`blocks drop and picker when ${'disabled' in props ? 'disabled' : 'full'}`, () => {
      const wrapper=mount(FlareMediaUpload,{props:{...base,...props}});
      expect(drag(wrapper.element,'drop').defaultPrevented).toBe(true);
      expect(wrapper.emitted('select')).toBeUndefined();
      expect(wrapper.get('input[type="file"]').attributes('disabled')).toBeDefined(); wrapper.unmount();
    });
  }
  it('does not intercept text drags or empty drops', () => {
    const wrapper=mount(FlareMediaUpload,{props:base});
    expect(drag(wrapper.element,'drop',[],['text/plain']).defaultPrevented).toBe(false);
    drag(wrapper.element,'drop',[]); expect(wrapper.emitted('select')).toBeUndefined(); wrapper.unmount();
  });
  it('offers state-specific recovery by stable ID and leaves results controlled', async () => {
    const items=[{id:'failed',name:'report.pdf',state:'failed' as const,statusText:'Offline'}, {id:'busy',name:'photo.png',state:'uploading' as const,statusText:'45%',progress:45}, {id:'selected',name:'local.txt',state:'selected' as const,statusText:'Ready'}];
    const wrapper=mount(FlareMediaUpload,{props:{...base,items,error:'Batch retained'}});
    for (const [label,event,id] of [['Retry: report.pdf','retry','failed'],['Cancel: photo.png','cancel','busy'],['Upload: local.txt','upload','selected'],['Remove: report.pdf','remove','failed']]) {
      await wrapper.get(`button[aria-label="${label}"]`).trigger('click'); expect(wrapper.emitted(event)).toEqual([[id]]);
    }
    expect(wrapper.find('button[aria-label="Remove: photo.png"]').exists()).toBe(false);
    expect(wrapper.get('progress').attributes('value')).toBe('45');
    expect(wrapper.findAll('[role="alert"]').map(row=>row.text())).toEqual(['Batch retained','Offline']);
    expect(wrapper.props('items')).toEqual(items);
    await wrapper.setProps({disabled:true}); await wrapper.get('button[aria-label="Retry: report.pdf"]').trigger('click');
    expect(wrapper.emitted('retry')).toHaveLength(1); wrapper.unmount();
  });
  it('uses a single trailing add tile for empty and partial image grids, reopening after removal', async () => {
    const wrapper = mount(FlareMediaUpload, { props: { ...base, layout: 'images', maxCount: 2 } });
    const input = wrapper.get('input[type="file"]').element as HTMLInputElement;
    const choose = vi.spyOn(input, 'click');
    expect(wrapper.findComponent(FlareFileUpload).exists()).toBe(false);
    expect(wrapper.findAll('ul > li')).toHaveLength(1);
    await wrapper.get('button[aria-label="Choose: Attachments"]').trigger('click');
    expect(choose).toHaveBeenCalledTimes(1);
    const item = { id: 'first', name: 'first.png', state: 'uploaded' as const, statusText: 'Done' };
    await wrapper.setProps({ items: [item] });
    expect(wrapper.findAll('ul > li')).toHaveLength(2);
    expect(wrapper.findAll('ul > li').at(-1)!.find('button[aria-label="Choose: Attachments"]').exists()).toBe(true);
    await wrapper.setProps({ items: [item, { ...item, id: 'second' }] });
    expect(wrapper.find('button[aria-label="Choose: Attachments"]').exists()).toBe(false);
    await wrapper.setProps({ items: [item] });
    expect(wrapper.find('button[aria-label="Choose: Attachments"]').exists()).toBe(true);
    await wrapper.setProps({ disabled: true });
    await wrapper.get('button[aria-label="Choose: Attachments"]').trigger('click');
    expect(choose).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });
  it('keeps image batch selection ordered through the in-grid picker and drop area', async () => {
    const wrapper = mount(FlareMediaUpload, { props: { ...base, layout: 'images', maxCount: 9 } });
    const input = wrapper.get('input[type="file"]').element as HTMLInputElement;
    Object.defineProperty(input, 'files', { configurable: true, value: files });
    await wrapper.get('input[type="file"]').trigger('change');
    drag(wrapper.get('.flare-media-upload__add').element, 'drop');
    expect(wrapper.emitted('select')).toEqual([[files], [files]]);
    expect(input.value).toBe('');
    await wrapper.setProps({ showPicker: false });
    expect(wrapper.find('button[aria-label="Choose: Attachments"]').exists()).toBe(false);
    expect(wrapper.find('ul').exists()).toBe(false);
    wrapper.unmount();
  });
  it('routes completed image preview separately from removal', async () => {
    const wrapper=mount(FlareMediaUpload,{props:{...base,layout:'images',previewLabel:'Preview',items:[{id:'image',name:'photo.png',state:'uploaded',statusText:'Done',previewUrl:'blob:host-owned'}]}});
    await wrapper.get('button[aria-label="Preview: photo.png"]').trigger('click');
    expect(wrapper.emitted('preview')).toEqual([['image']]); expect(wrapper.emitted('remove')).toBeUndefined(); wrapper.unmount();
  });
  it('reviews a selection without opening a second picker or accepting another drop', async () => {
    const wrapper = mount(FlareMediaUpload, { props: { ...base, showPicker: false, layout: 'images', items: [
      { id: 'ready', name: 'first.png', state: 'selected', statusText: 'Ready', previewUrl: 'blob:host-owned' },
    ] } });
    expect(wrapper.find('input[type="file"]').exists()).toBe(false);
    expect(wrapper.findComponent(FlareFileUpload).exists()).toBe(false);
    drag(wrapper.element, 'drop');
    expect(wrapper.emitted('select')).toBeUndefined();
    await wrapper.get('button[aria-label="Remove: first.png"]').trigger('click');
    expect(wrapper.emitted('remove')).toEqual([['ready']]);
    wrapper.unmount();
  });
  it('allows cancelling a queued selection while another item is locked in flight', async () => {
    const wrapper = mount(FlareMediaUpload, { props: { ...base, showPicker: false, items: [
      { id: 'active', name: 'active.png', state: 'uploading', statusText: 'Uploading', disabled: true },
      { id: 'queued', name: 'queued.png', state: 'selected', statusText: 'Ready' },
    ] } });
    expect(wrapper.get('progress').attributes('value')).toBeUndefined();
    await wrapper.get('button[aria-label="Cancel: active.png"]').trigger('click');
    expect(wrapper.emitted('cancel')).toBeUndefined();
    await wrapper.get('button[aria-label="Remove: queued.png"]').trigger('click');
    expect(wrapper.emitted('remove')).toEqual([['queued']]);
    wrapper.unmount();
  });
  it('keeps idle images as thumbnails with accessible names and icon-only removal', async () => {
    const wrapper = mount(FlareMediaUpload, { props: { ...base, showPicker: false, layout: 'images', uploadLabel: undefined, previewLabel: 'Preview', items: [
      { id: 'selected', name: 'first.png', state: 'selected', statusText: 'Ready to send', previewUrl: 'blob:first' },
      { id: 'uploaded', name: 'second.png', state: 'uploaded', statusText: 'Uploaded', previewUrl: 'blob:second' },
    ] } });
    expect(wrapper.findAll('.flare-media-upload__item h3')).toHaveLength(0);
    expect(wrapper.text()).not.toContain('Ready to send');
    expect(wrapper.text()).not.toContain('Uploaded');
    expect(wrapper.get('button[aria-label="Preview: first.png"]').attributes('disabled')).toBeUndefined();
    const remove = wrapper.get('button[aria-label="Remove: first.png"]');
    expect(remove.text()).toBe('');
    await remove.trigger('click');
    expect(wrapper.emitted('remove')).toEqual([['selected']]);
    expect(wrapper.emitted('preview')).toBeUndefined();
    expect(wrapper.props('items')).toHaveLength(2);
    wrapper.unmount();
  });
  it('emits preview for selected and failed local images without starting or retrying uploads', async () => {
    const preview = vi.fn();
    const wrapper = mount(FlareMediaUpload, { props: { ...base, showPicker: false, layout: 'images', previewLabel: 'Preview', onPreview: preview, items: [
      { id: 'selected', name: 'first.png', state: 'selected', statusText: 'Ready', previewUrl: 'blob:first' },
      { id: 'failed', name: 'second.png', state: 'failed', statusText: 'Offline', previewUrl: 'blob:second' },
    ] } });
    await wrapper.get('button[aria-label="Preview: first.png"]').trigger('click');
    await wrapper.get('button[aria-label="Preview: second.png"]').trigger('click');
    expect(preview.mock.calls).toEqual([['selected'], ['failed']]);
    expect(wrapper.emitted('upload')).toBeUndefined();
    expect(wrapper.emitted('retry')).toBeUndefined();
    expect(wrapper.emitted('remove')).toBeUndefined();
    await wrapper.setProps({ disabled: true });
    await wrapper.get('button[aria-label="Preview: first.png"]').trigger('click');
    expect(preview).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });
  it('retains real image progress and independent retry/cancel controls inside thumbnails', async () => {
    const wrapper = mount(FlareMediaUpload, { props: { ...base, showPicker: false, layout: 'images', previewLabel: 'Preview', items: [
      { id: 'busy', name: 'busy.png', state: 'uploading', statusText: 'Uploading', progress: 45, previewUrl: 'blob:busy' },
      { id: 'unknown', name: 'unknown.png', state: 'uploading', statusText: 'Uploading', previewUrl: 'blob:unknown' },
      { id: 'failed', name: 'failed.png', state: 'failed', statusText: 'Offline', previewUrl: 'blob:failed' },
    ] } });
    const progress = wrapper.findAll('progress');
    expect(progress[0].attributes('value')).toBe('45');
    expect(progress[1].attributes('value')).toBeUndefined();
    expect(wrapper.get('[role="alert"]').text()).toContain('Offline');
    await wrapper.get('button[aria-label="Cancel: busy.png"]').trigger('click');
    await wrapper.get('button[aria-label="Retry: failed.png"]').trigger('click');
    expect(wrapper.emitted('cancel')).toEqual([['busy']]);
    expect(wrapper.emitted('retry')).toEqual([['failed']]);
    expect(wrapper.emitted('preview')).toBeUndefined();
    expect(wrapper.find('button[aria-label="Remove: busy.png"]').exists()).toBe(false);
    wrapper.unmount();
  });
});
describe('single FileUpload drop policy', () => {
  it('keeps the single-file contract while sharing the drop behavior', () => {
    const wrapper=mount(FlareFileUpload,{props:{title:'Material',state:'empty',statusText:'Choose',pickLabel:'Choose'}});
    drag(wrapper.element,'drop'); expect(wrapper.emitted('select')).toEqual([[files[0]]]); wrapper.unmount();
  });
  for (const props of [{disabled:true},{state:'uploading' as const},{state:'uploaded' as const},{hostPicker:true}]) {
    it(`ignores DOM bytes for ${JSON.stringify(props)}`, () => {
      const wrapper=mount(FlareFileUpload,{props:{title:'Material',state:'empty',statusText:'Choose',pickLabel:'Choose',...props}});
      drag(wrapper.element,'drop'); expect(wrapper.emitted('select')).toBeUndefined(); wrapper.unmount();
    });
  }
});
