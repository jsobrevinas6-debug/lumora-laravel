@php
    $formId = $formId ?? null;
    $includeReason = $includeReason ?? false;
    $required = $required ?? true;
@endphp

<div class="form-group seller-application-field">
    <label for="business_name">Business Name</label>
    <input type="text" name="business_name" id="business_name" value="{{ old('business_name') }}" @if($formId) form="{{ $formId }}" @endif @required($required)>
    @error('business_name')<span class="field-error">{{ $message }}</span>@enderror
</div>

<div class="form-group seller-application-field">
    <label for="category">Line of Business (Category)</label>
    <select name="category" id="category" @if($formId) form="{{ $formId }}" @endif @required($required)>
        <option value="">Select a category</option>
        @foreach (config('categories') as $cat)
            <option value="{{ $cat }}" @selected(old('category') === $cat)>{{ $cat }}</option>
        @endforeach
    </select>
    @error('category')<span class="field-error">{{ $message }}</span>@enderror
</div>

<div class="form-group seller-application-field">
    <label for="id_document">Upload Valid ID</label>
    <input type="file" name="id_document" id="id_document" accept="image/*,.pdf" @if($formId) form="{{ $formId }}" @endif @required($required)>
    @error('id_document')<span class="field-error">{{ $message }}</span>@enderror
</div>

<div class="form-group seller-application-field">
    <label for="business_permit">Upload Business Permit</label>
    <input type="file" name="business_permit" id="business_permit" accept="image/*,.pdf" @if($formId) form="{{ $formId }}" @endif @required($required)>
    @error('business_permit')<span class="field-error">{{ $message }}</span>@enderror
</div>

@if ($includeReason)
    <div class="form-group seller-application-field">
        <label for="reason">Application Details</label>
        <textarea name="reason" id="reason" maxlength="2000" placeholder="Share the products you plan to offer and anything the admin should know." @if($formId) form="{{ $formId }}" @endif>{{ old('reason') }}</textarea>
        @error('reason')<span class="field-error">{{ $message }}</span>@enderror
    </div>
@endif
